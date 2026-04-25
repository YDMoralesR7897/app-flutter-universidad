"""Inserta aulas de demo. Coordenadas sobre el emulador Android por defecto
(Google HQ, Mountain View) para que el GPS virtual caiga dentro del radio."""
from app.db import Base, SessionLocal, engine
from app import models

CLASSES = [
    {"code": "AULA-101", "name": "Cálculo I", "lat": 37.4219983, "lng": -122.084, "radius_m": 500},
    {"code": "AULA-102", "name": "Programación Móvil", "lat": 37.4220, "lng": -122.0841, "radius_m": 300},
    {"code": "AULA-201", "name": "Seguridad Informática", "lat": 37.4221, "lng": -122.0842, "radius_m": 200},
    {"code": "LAB-A", "name": "Laboratorio de Redes", "lat": 37.4230, "lng": -122.0830, "radius_m": 150},
]


def main():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        for c in CLASSES:
            existing = db.query(models.ClassRoom).filter_by(code=c["code"]).one_or_none()
            if existing:
                for k, v in c.items():
                    setattr(existing, k, v)
            else:
                db.add(models.ClassRoom(**c))
        db.commit()
        print(f"Seeded {len(CLASSES)} classrooms.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
