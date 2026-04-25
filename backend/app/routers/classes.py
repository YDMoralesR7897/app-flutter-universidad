import math
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..deps import current_user

router = APIRouter(tags=["campus"])


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


@router.get("/classes", response_model=list[schemas.ClassRoomOut])
def list_classes(
    db: Session = Depends(get_db),
    _: models.User = Depends(current_user),
):
    return db.scalars(select(models.ClassRoom).order_by(models.ClassRoom.code)).all()


@router.post(
    "/checkins",
    response_model=schemas.CheckInOut,
    status_code=status.HTTP_201_CREATED,
)
def create_checkin(
    data: schemas.CheckInIn,
    db: Session = Depends(get_db),
    user: models.User = Depends(current_user),
):
    room = db.get(models.ClassRoom, data.classroom_id)
    if room is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "classroom_not_found")

    distance = _haversine_m(data.lat, data.lng, room.lat, room.lng)
    if distance > room.radius_m:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"out_of_geofence:{int(distance)}m",
        )

    checkin = models.CheckIn(
        user_id=user.id,
        classroom_id=room.id,
        lat=data.lat,
        lng=data.lng,
        distance_m=distance,
        created_at=datetime.utcnow(),
    )
    db.add(checkin)
    db.commit()
    db.refresh(checkin)
    return schemas.CheckInOut(
        id=checkin.id,
        classroom_id=room.id,
        classroom_name=room.name,
        lat=checkin.lat,
        lng=checkin.lng,
        distance_m=checkin.distance_m,
        created_at=checkin.created_at,
    )


@router.get("/checkins", response_model=list[schemas.CheckInOut])
def list_my_checkins(
    db: Session = Depends(get_db),
    user: models.User = Depends(current_user),
):
    rows = db.execute(
        select(models.CheckIn, models.ClassRoom)
        .join(models.ClassRoom, models.ClassRoom.id == models.CheckIn.classroom_id)
        .where(models.CheckIn.user_id == user.id)
        .order_by(models.CheckIn.created_at.desc())
        .limit(50),
    ).all()
    return [
        schemas.CheckInOut(
            id=c.id,
            classroom_id=c.classroom_id,
            classroom_name=room.name,
            lat=c.lat,
            lng=c.lng,
            distance_m=c.distance_m,
            created_at=c.created_at,
        )
        for c, room in rows
    ]
