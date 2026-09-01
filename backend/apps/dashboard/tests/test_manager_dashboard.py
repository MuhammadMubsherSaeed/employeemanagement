from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext

from apps.accounts.models import UserRole
from apps.attendance.models import Attendance, AttendanceStatus
from apps.attendance.tests.fixtures import LATE, ON_TIME, freeze_now
from apps.companies.services import MembershipService
from apps.dashboard.tests import MANAGER, DashboardFixtureMixin
from apps.employees.models import Employee, EmploymentType
from apps.leave.models import LeaveRequestStatus
from apps.leave.tests.fixtures import TODAY


class ManagerDashboardTests(DashboardFixtureMixin, TestCase):
    def test_team_scope_and_attendance(self) -> None:
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_a2,
            date=TODAY,
            check_in=LATE,
            status=AttendanceStatus.LATE,
        )
        Attendance.objects.create(
            company=self.company_a,
            employee=self.emp_manager_a,
            date=TODAY,
            check_in=LATE,
            status=AttendanceStatus.LATE,
        )
        self.pending_request(employee=self.emp_a1)
        self.pending_request(employee=self.emp_a2)
        client = self.authenticate(self.manager_a)
        with freeze_now(ON_TIME):
            response = client.get(MANAGER)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["team_size"], 2)
        self.assertEqual(data["team_present"], 1)
        self.assertEqual(data["team_late"], 1)
        self.assertEqual(data["team_absent"], 0)
        self.assertEqual(data["team_on_leave"], 0)
        self.assertEqual(data["pending_leave_requests"], 1)

    def test_does_not_include_unmanaged_or_other_company(self) -> None:
        Attendance.objects.create(
            company=self.company_b,
            employee=self.emp_b1,
            date=TODAY,
            check_in=ON_TIME,
            status=AttendanceStatus.PRESENT,
        )
        self.pending_request(employee=self.emp_b1, leave_type=self.type_b)
        outsider = Employee.objects.create(
            company=self.company_a,
            employee_code="EMP-OUT",
            first_name="Out",
            last_name="Sider",
            department=self.dept_a,
            position=self.pos_a,
            manager=self.emp_admin_a,
            employment_type=EmploymentType.FULL_TIME,
        )
        self.pending_request(employee=outsider)
        client = self.authenticate(self.manager_a)
        with freeze_now(ON_TIME):
            data = client.get(
                MANAGER, {"company_id": str(self.company_b.id)}
            ).json()["data"]
        self.assertEqual(data["team_size"], 2)
        self.assertEqual(data["team_present"], 0)
        self.assertEqual(data["pending_leave_requests"], 0)

    def test_manager_without_team_members(self) -> None:
        user = self._member("manager-empty@example.com", UserRole.MANAGER)
        MembershipService().assign(
            user=user,
            company=self.company_a,
            role=self.roles[UserRole.MANAGER],
        )
        client = self.authenticate(user)
        with freeze_now(ON_TIME):
            data = client.get(MANAGER).json()["data"]
        self.assertEqual(data["team_size"], 0)
        self.assertEqual(data["team_present"], 0)
        self.assertEqual(data["team_absent"], 0)
        self.assertEqual(data["team_late"], 0)
        self.assertEqual(data["team_on_leave"], 0)
        self.assertEqual(data["pending_leave_requests"], 0)
        self.assertEqual(data["recent_activity"], [])

    def test_on_leave_and_activity_are_team_scoped(self) -> None:
        from apps.common.events import emit

        self.pending_request(
            employee=self.emp_a1, status=LeaveRequestStatus.APPROVED
        )
        emit(
            "leave.approved",
            actor=self.manager_a,
            company=self.company_a,
            resource="leave.LeaveRequest",
            resource_id="team",
        )
        emit(
            "settings.changed",
            actor=self.admin_a,
            company=self.company_a,
            resource="companies.CompanySettings",
            resource_id="secret",
        )
        emit(
            "leave.approved",
            actor=self.admin_b,
            company=self.company_b,
            resource="leave.LeaveRequest",
            resource_id="other",
        )
        client = self.authenticate(self.manager_a)
        with freeze_now(ON_TIME):
            data = client.get(MANAGER).json()["data"]
        self.assertEqual(data["team_on_leave"], 1)
        actions = {row["action"] for row in data["recent_activity"]}
        self.assertIn("leave.approved", actions)
        self.assertNotIn("settings.changed", actions)
        ids = {row["resource_id"] for row in data["recent_activity"]}
        self.assertNotIn("other", ids)
        self.assertNotIn("secret", ids)

    def test_query_count_stays_bounded_for_large_team(self) -> None:
        for index in range(12):
            Employee.objects.create(
                company=self.company_a,
                employee_code=f"EMP-T{index:02d}",
                first_name="Report",
                last_name=str(index),
                department=self.dept_a,
                position=self.pos_a,
                manager=self.emp_manager_a,
            )
        client = self.authenticate(self.manager_a)
        with freeze_now(ON_TIME):
            with CaptureQueriesContext(connection) as captured:
                response = client.get(MANAGER)
        self.assertEqual(response.status_code, 200)
        self.assertLessEqual(len(captured.captured_queries), 40)
        self.assertEqual(response.json()["data"]["team_size"], 14)
