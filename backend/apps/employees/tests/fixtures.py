from django.core.management import call_command

from apps.accounts.models import UserRole
from apps.companies.services import MembershipService
from apps.companies.tests.fixtures import TenancyFixtureMixin
from apps.employees.models import (
    Department,
    Employee,
    EmployeeStatus,
    EmploymentType,
    OrgStatus,
    Position,
)

EMPLOYEES = "/api/v1/employees"
DEPARTMENTS = "/api/v1/departments"
POSITIONS = "/api/v1/positions"


class EmployeeFixtureMixin(TenancyFixtureMixin):
    @classmethod
    def setUpTestData(cls) -> None:
        super().setUpTestData()
        call_command("seed_rbac", verbosity=0)
        service = MembershipService()
        cls.employee_a2 = cls._member(
            "employee-a2@example.com", UserRole.EMPLOYEE
        )
        service.assign(
            user=cls.employee_a2,
            company=cls.company_a,
            role=cls.roles[UserRole.EMPLOYEE],
        )
        cls.dept_a = Department.objects.create(
            company=cls.company_a,
            name="Engineering",
            status=OrgStatus.ACTIVE,
        )
        cls.dept_a_hr = Department.objects.create(
            company=cls.company_a,
            name="Human Resources",
            status=OrgStatus.ACTIVE,
        )
        cls.dept_b = Department.objects.create(
            company=cls.company_b,
            name="Engineering",
            status=OrgStatus.ACTIVE,
        )
        cls.pos_a = Position.objects.create(
            company=cls.company_a,
            department=cls.dept_a,
            title="Engineer",
            status=OrgStatus.ACTIVE,
        )
        cls.pos_a_hr = Position.objects.create(
            company=cls.company_a,
            department=cls.dept_a_hr,
            title="HR Specialist",
            status=OrgStatus.ACTIVE,
        )
        cls.pos_b = Position.objects.create(
            company=cls.company_b,
            department=cls.dept_b,
            title="Engineer",
            status=OrgStatus.ACTIVE,
        )
        cls.emp_admin_a = Employee.objects.create(
            company=cls.company_a,
            user=cls.admin_a,
            employee_code="EMP-ADMIN",
            first_name="Admin",
            last_name="Acme",
            department=cls.dept_a,
            position=cls.pos_a,
            employment_type=EmploymentType.FULL_TIME,
            status=EmployeeStatus.ACTIVE,
        )
        cls.emp_manager_a = Employee.objects.create(
            company=cls.company_a,
            user=cls.manager_a,
            employee_code="EMP-MGR",
            first_name="Manager",
            last_name="Acme",
            department=cls.dept_a,
            position=cls.pos_a,
            phone="111-1111",
            address="1 Manager Way",
            date_of_birth="1990-01-01",
            emergency_contact_name="Pat",
            emergency_contact_relationship="Spouse",
            emergency_contact_phone="111-0000",
        )
        cls.emp_a1 = Employee.objects.create(
            company=cls.company_a,
            user=cls.employee_a,
            employee_code="EMP-001",
            first_name="Ada",
            last_name="Acme",
            department=cls.dept_a,
            position=cls.pos_a,
            manager=cls.emp_manager_a,
            phone="222-2222",
            address="2 Worker Lane",
            date_of_birth="1992-02-02",
            emergency_contact_name="Sam",
            emergency_contact_relationship="Sibling",
            emergency_contact_phone="222-0000",
        )
        cls.emp_a2 = Employee.objects.create(
            company=cls.company_a,
            user=cls.employee_a2,
            employee_code="EMP-002",
            first_name="Nia",
            last_name="Acme",
            department=cls.dept_a_hr,
            position=cls.pos_a_hr,
            phone="333-3333",
            address="3 Other Ave",
        )
        cls.emp_admin_b = Employee.objects.create(
            company=cls.company_b,
            user=cls.admin_b,
            employee_code="EMP-ADMIN",
            first_name="Admin",
            last_name="Beta",
            department=cls.dept_b,
            position=cls.pos_b,
        )
        cls.emp_b1 = Employee.objects.create(
            company=cls.company_b,
            user=cls.employee_b,
            employee_code="EMP-001",
            first_name="Bea",
            last_name="Beta",
            department=cls.dept_b,
            position=cls.pos_b,
            phone="999-9999",
            address="9 Beta Blvd",
        )
        cls.emp_b2 = Employee.objects.create(
            company=cls.company_b,
            user=cls.manager_b,
            employee_code="EMP-002",
            first_name="Mo",
            last_name="Beta",
            department=cls.dept_b,
            position=cls.pos_b,
        )


def ids(response) -> set[str]:
    payload = response.json()["data"]
    rows = payload["results"] if isinstance(payload, dict) else payload
    return {row["id"] for row in rows}
