from datetime import datetime
import os

import pytest

os.environ["TESTING"] = "true"

from app import ADMIN_PASSWORD, Booking, Match, SeatType, Stadium, app, db
from seed_world_cup_2026 import STAGE_PRICES, seed_world_cup_2026_data


@pytest.fixture()
def client():
    app.config["TESTING"] = True

    with app.app_context():
        db.drop_all()
        db.create_all()
        stadium = Stadium(
            name="Test Stadium",
            city="Test City",
            capacity=50000,
        )
        match = Match(
            match_number=999,
            stage="Group Stage",
            stage_order=1,
            group_name="Group Test",
            home_team="Team A",
            away_team="Team B",
            home_placeholder=False,
            away_placeholder=False,
            match_date=datetime(2026, 6, 11, 20, 0),
            kickoff_time="20:00",
            stadium=stadium,
        )
        match.seat_types = [
            SeatType(name="Regular", price=100.0, total_seats=100),
            SeatType(name="VIP", price=500.0, total_seats=10),
        ]
        booking = Booking(
            booking_code="TEST-CODE-123",
            customer_name="Test Customer",
            customer_email="customer@example.com",
            seats_count=2,
            match=match,
            seat_type=match.seat_types[0],
        )
        cancelled_booking = Booking(
            booking_code="TEST-CANCELLED-123",
            customer_name="Cancelled Customer",
            customer_email="cancelled@example.com",
            seats_count=1,
            is_cancelled=True,
            match=match,
            seat_type=match.seat_types[0],
        )
        db.session.add(match)
        db.session.add(booking)
        db.session.add(cancelled_booking)
        db.session.commit()

    yield app.test_client()

    with app.app_context():
        db.session.remove()
        db.drop_all()


def test_health_route(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_home_page_returns_200(client):
    response = client.get("/")

    assert response.status_code == 200
    assert b"Team A vs Team B" in response.data
    assert b"Group Stage" in response.data


def test_match_detail_page_returns_200(client):
    with app.app_context():
        match = Match.query.first()

    response = client.get(f"/matches/{match.id}")

    assert response.status_code == 200
    assert b"Book seats" in response.data


def test_manage_booking_page_returns_200(client):
    response = client.get("/manage-booking")

    assert response.status_code == 200
    assert b"Manage your booking" in response.data


def test_about_page_returns_200(client):
    response = client.get("/about")

    assert response.status_code == 200
    assert b"World Cup seat booking demo app" in response.data


def test_invalid_booking_lookup_shows_error(client):
    response = client.post(
        "/manage-booking",
        data={
            "booking_code": "BAD-CODE",
            "customer_email": "missing@example.com",
        },
    )

    assert response.status_code == 200
    assert b"Booking was not found" in response.data


def test_booking_detail_page_returns_200(client):
    response = client.get("/bookings/TEST-CODE-123")

    assert response.status_code == 200
    assert b"TEST-CODE-123" in response.data
    assert b"Active" in response.data


def test_cancel_route_sets_booking_cancelled(client):
    response = client.post("/bookings/TEST-CODE-123/cancel")

    assert response.status_code == 302

    with app.app_context():
        booking = Booking.query.filter_by(booking_code="TEST-CODE-123").first()
        assert booking.is_cancelled is True


def test_admin_bookings_page_renders_statistics(client):
    with client.session_transaction() as sess:
        sess["admin_logged_in"] = True

    response = client.get("/admin/bookings")

    assert response.status_code == 200
    assert b"Match statistics" in response.data
    assert b"Active booked seats" in response.data


def test_admin_bookings_redirects_when_not_logged_in(client):
    response = client.get("/admin/bookings")

    assert response.status_code == 302
    assert response.headers["Location"].endswith("/admin/login")


def test_admin_login_rejects_invalid_password(client):
    response = client.post("/admin/login", data={"password": "wrong-password"})

    assert response.status_code == 200
    assert b"Invalid admin password" in response.data

    with client.session_transaction() as sess:
        assert not sess.get("admin_logged_in")


def test_admin_login_accepts_configured_password(client):
    response = client.post("/admin/login", data={"password": ADMIN_PASSWORD})

    assert response.status_code == 302
    assert response.headers["Location"].endswith("/admin/bookings")

    with client.session_transaction() as sess:
        assert sess["admin_logged_in"] is True
        assert sess.permanent is True


def test_admin_logout_clears_session(client):
    with client.session_transaction() as sess:
        sess["admin_logged_in"] = True
        sess["other_value"] = "remove-me"

    response = client.get("/admin/logout")

    assert response.status_code == 302
    with client.session_transaction() as sess:
        assert "admin_logged_in" not in sess
        assert "other_value" not in sess


def test_match_model_supports_world_cup_schedule_fields(client):
    with app.app_context():
        match = Match.query.first()

        assert match.match_number == 999
        assert match.stage == "Group Stage"
        assert match.stage_order == 1
        assert match.group_name == "Group Test"
        assert match.kickoff_time == "20:00"
        assert match.home_placeholder is False
        assert match.away_placeholder is False


def test_world_cup_seed_creates_matches_without_duplicates(client):
    with app.app_context():
        db.drop_all()
        db.create_all()

        seed_world_cup_2026_data(db, Stadium, Match, SeatType)
        first_count = Match.query.filter(Match.match_number.isnot(None)).count()

        seed_world_cup_2026_data(db, Stadium, Match, SeatType)
        second_count = Match.query.filter(Match.match_number.isnot(None)).count()

        assert first_count == 104
        assert second_count == 104


def test_stage_based_pricing_is_seeded(client):
    with app.app_context():
        db.drop_all()
        db.create_all()
        seed_world_cup_2026_data(db, Stadium, Match, SeatType)

        group_match = Match.query.filter_by(stage="Group Stage").first()
        final_match = Match.query.filter_by(stage="Final").first()

        group_prices = {seat.name: seat.price for seat in group_match.seat_types}
        final_prices = {seat.name: seat.price for seat in final_match.seat_types}

        assert group_prices["Regular"] == STAGE_PRICES["Group Stage"]["Regular"]
        assert final_prices["VIP"] == STAGE_PRICES["Final"]["VIP"]


def test_seed_has_group_stage_and_knockout_placeholder(client):
    with app.app_context():
        db.drop_all()
        db.create_all()
        seed_world_cup_2026_data(db, Stadium, Match, SeatType)

        group_match = Match.query.filter_by(stage="Group Stage", group_name="Group A").first()
        knockout_match = Match.query.filter_by(stage="Round of 32").first()

        assert group_match is not None
        assert group_match.home_placeholder is False
        assert knockout_match is not None
        assert "Group" in knockout_match.home_team
        assert knockout_match.home_placeholder is True
