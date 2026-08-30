from datetime import date

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import Role, RoleScope, UserRole
from apps.companies.models import Company, RecordVisibility, TenantOwnedRecord
from apps.companies.services import MembershipService
from apps.employees.models import (
    Department,
    Employee,
    EmployeeStatus,
    EmploymentType,
    Gender,
    OrgStatus,
    Position,
)

User = get_user_model()

DEMO_PASSWORD = "DemoPass123!"

COMPANIES = (
    {
        "slug": "acme",
        "name": "Acme Technologies",
        "email": "hello@acme.example.com",
        "phone": "+1-415-555-0101",
        "website": "https://acme.example.com",
        "is_active": True,
    },
    {
        "slug": "beta",
        "name": "Beta Labs",
        "email": "hello@beta.example.com",
        "phone": "+1-415-555-0102",
        "website": "https://beta.example.com",
        "is_active": True,
    },
    {
        "slug": "gamma",
        "name": "Gamma Foods",
        "email": "hello@gamma.example.com",
        "phone": "+1-415-555-0103",
        "website": "https://gamma.example.com",
        "is_active": True,
    },
    {
        "slug": "delta",
        "name": "Delta Health",
        "email": "hello@delta.example.com",
        "phone": "+1-415-555-0104",
        "website": "https://delta.example.com",
        "is_active": True,
    },
    {
        "slug": "epsilon",
        "name": "Epsilon Media",
        "email": "hello@epsilon.example.com",
        "phone": "+1-415-555-0105",
        "website": "https://epsilon.example.com",
        "is_active": False,
    },
)

USERS = (
    {
        "email": "ops@bestech.example.com",
        "first_name": "Platform",
        "last_name": "Operator",
        "role": UserRole.SUPER_ADMIN,
        "is_superuser": True,
        "is_staff": True,
    },
    {
        "email": "james.carter@acme.example.com",
        "first_name": "James",
        "last_name": "Carter",
        "role": UserRole.COMPANY_ADMIN,
    },
    {
        "email": "priya.shah@acme.example.com",
        "first_name": "Priya",
        "last_name": "Shah",
        "role": UserRole.MANAGER,
    },
    {
        "email": "ada.lovelace@acme.example.com",
        "first_name": "Ada",
        "last_name": "Lovelace",
        "role": UserRole.EMPLOYEE,
    },
    {
        "email": "nia.okonkwo@acme.example.com",
        "first_name": "Nia",
        "last_name": "Okonkwo",
        "role": UserRole.EMPLOYEE,
    },
    {
        "email": "omar.hassan@acme.example.com",
        "first_name": "Omar",
        "last_name": "Hassan",
        "role": UserRole.EMPLOYEE,
    },
)

DEPARTMENTS = (
    ("Engineering", "Product engineering and infrastructure."),
    ("Human Resources", "People operations and employee support."),
    ("Finance", "Accounting, payroll, and financial planning."),
    ("Sales", "New business and account management."),
    ("Operations", "Facilities, vendors, and day-to-day operations."),
)

POSITIONS = (
    ("Engineering", "Engineering Manager", "Leads the engineering team."),
    ("Human Resources", "HR Specialist", "Owns hiring and employee records."),
    ("Finance", "Accountant", "Company accounting and payroll."),
    ("Sales", "Sales Executive", "Owns the sales pipeline."),
    ("Operations", "Operations Coordinator", "Coordinates office operations."),
)

EMPLOYEES = (
    {
        "email": "james.carter@acme.example.com",
        "employee_code": "EMP-001",
        "department": "Finance",
        "position": "Accountant",
        "gender": Gender.MALE,
        "date_of_birth": date(1984, 3, 12),
        "phone": "+1-415-555-1001",
        "address": "100 Market Street, San Francisco, CA",
        "emergency_contact_name": "Helen Carter",
        "emergency_contact_relationship": "Spouse",
        "emergency_contact_phone": "+1-415-555-2001",
        "joining_date": date(2018, 1, 8),
        "employment_type": EmploymentType.FULL_TIME,
        "status": EmployeeStatus.ACTIVE,
        "manager_email": None,
    },
    {
        "email": "priya.shah@acme.example.com",
        "employee_code": "EMP-002",
        "department": "Engineering",
        "position": "Engineering Manager",
        "gender": Gender.FEMALE,
        "date_of_birth": date(1988, 7, 21),
        "phone": "+1-415-555-1002",
        "address": "200 Mission Street, San Francisco, CA",
        "emergency_contact_name": "Ravi Shah",
        "emergency_contact_relationship": "Spouse",
        "emergency_contact_phone": "+1-415-555-2002",
        "joining_date": date(2019, 4, 15),
        "employment_type": EmploymentType.FULL_TIME,
        "status": EmployeeStatus.ACTIVE,
        "manager_email": "james.carter@acme.example.com",
    },
    {
        "email": "ada.lovelace@acme.example.com",
        "employee_code": "EMP-003",
        "department": "Human Resources",
        "position": "HR Specialist",
        "gender": Gender.FEMALE,
        "date_of_birth": date(1991, 12, 10),
        "phone": "+1-415-555-1003",
        "address": "300 Folsom Street, San Francisco, CA",
        "emergency_contact_name": "Annabella Lovelace",
        "emergency_contact_relationship": "Parent",
        "emergency_contact_phone": "+1-415-555-2003",
        "joining_date": date(2021, 6, 1),
        "employment_type": EmploymentType.FULL_TIME,
        "status": EmployeeStatus.ACTIVE,
        "manager_email": "priya.shah@acme.example.com",
    },
    {
        "email": "nia.okonkwo@acme.example.com",
        "employee_code": "EMP-004",
        "department": "Sales",
        "position": "Sales Executive",
        "gender": Gender.FEMALE,
        "date_of_birth": date(1993, 5, 4),
        "phone": "+1-415-555-1004",
        "address": "400 Brannan Street, San Francisco, CA",
        "emergency_contact_name": "Chike Okonkwo",
        "emergency_contact_relationship": "Sibling",
        "emergency_contact_phone": "+1-415-555-2004",
        "joining_date": date(2022, 9, 12),
        "employment_type": EmploymentType.PART_TIME,
        "status": EmployeeStatus.ON_LEAVE,
        "manager_email": "priya.shah@acme.example.com",
    },
    {
        "email": "omar.hassan@acme.example.com",
        "employee_code": "EMP-005",
        "department": "Operations",
        "position": "Operations Coordinator",
        "gender": Gender.MALE,
        "date_of_birth": date(1990, 11, 18),
        "phone": "+1-415-555-1005",
        "address": "500 Howard Street, San Francisco, CA",
        "emergency_contact_name": "Layla Hassan",
        "emergency_contact_relationship": "Spouse",
        "emergency_contact_phone": "+1-415-555-2005",
        "joining_date": date(2020, 2, 3),
        "employment_type": EmploymentType.CONTRACT,
        "status": EmployeeStatus.ACTIVE,
        "manager_email": "priya.shah@acme.example.com",
    },
)

DEPARTMENT_MANAGERS = {
    "Engineering": "priya.shah@acme.example.com",
    "Human Resources": "ada.lovelace@acme.example.com",
    "Finance": "james.carter@acme.example.com",
    "Sales": "nia.okonkwo@acme.example.com",
    "Operations": "omar.hassan@acme.example.com",
}

OWNED_RECORDS = (
    {
        "title": "Q1 headcount plan",
        "visibility": RecordVisibility.COMPANY,
        "owner_email": "james.carter@acme.example.com",
        "assigned_email": "priya.shah@acme.example.com",
    },
    {
        "title": "Ada private notes",
        "visibility": RecordVisibility.PRIVATE,
        "owner_email": "ada.lovelace@acme.example.com",
        "assigned_email": None,
    },
    {
        "title": "Sales pipeline review",
        "visibility": RecordVisibility.COMPANY,
        "owner_email": "nia.okonkwo@acme.example.com",
        "assigned_email": "priya.shah@acme.example.com",
    },
    {
        "title": "Operations checklist",
        "visibility": RecordVisibility.COMPANY,
        "owner_email": "omar.hassan@acme.example.com",
        "assigned_email": None,
    },
    {
        "title": "HR policy draft",
        "visibility": RecordVisibility.PRIVATE,
        "owner_email": "ada.lovelace@acme.example.com",
        "assigned_email": "james.carter@acme.example.com",
    },
)


class Command(BaseCommand):
    help = (
        "Seed RBAC defaults plus five demo rows for companies, users, "
        "memberships, departments, positions, employees, and tenant records."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--password",
            default=DEMO_PASSWORD,
            help="Password assigned to newly created demo users.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        password = options["password"]
        call_command("seed_rbac", verbosity=0)

        roles = {
            role.code: role
            for role in Role.objects.filter(scope=RoleScope.COMPANY)
        }
        companies = self._seed_companies()
        users = self._seed_users(password)
        acme = companies["acme"]
        self._seed_memberships(users, acme, roles)
        departments = self._seed_departments(acme)
        positions = self._seed_positions(acme, departments)
        employees = self._seed_employees(acme, users, departments, positions)
        self._assign_managers(departments, employees)
        self._seed_records(acme, users)

        self.stdout.write(self.style.SUCCESS("Demo data is up to date."))
        self.stdout.write("Login password for seeded users: " + password)
        self.stdout.write("  ops@bestech.example.com          SUPER_ADMIN")
        self.stdout.write("  james.carter@acme.example.com    COMPANY_ADMIN @ Acme")
        self.stdout.write("  priya.shah@acme.example.com      MANAGER @ Acme")
        self.stdout.write("  ada.lovelace@acme.example.com    EMPLOYEE @ Acme")
        self.stdout.write("  nia.okonkwo@acme.example.com     EMPLOYEE @ Acme")
        self.stdout.write("  omar.hassan@acme.example.com     EMPLOYEE @ Acme")

    def _seed_companies(self) -> dict[str, Company]:
        companies = {}
        for spec in COMPANIES:
            company, _created = Company.objects.update_or_create(
                slug=spec["slug"],
                defaults={
                    "name": spec["name"],
                    "email": spec["email"],
                    "phone": spec["phone"],
                    "website": spec["website"],
                    "is_active": spec["is_active"],
                },
            )
            companies[company.slug] = company
        return companies

    def _seed_users(self, password: str) -> dict[str, User]:
        users = {}
        for spec in USERS:
            defaults = {
                "first_name": spec["first_name"],
                "last_name": spec["last_name"],
                "role": spec["role"],
                "is_staff": spec.get("is_staff", False),
                "is_superuser": spec.get("is_superuser", False),
                "is_active": True,
            }
            user = User.objects.filter(email=spec["email"]).first()
            if user is None:
                create = (
                    User.objects.create_superuser
                    if defaults["is_superuser"]
                    else User.objects.create_user
                )
                extra = {
                    key: value
                    for key, value in defaults.items()
                    if key != "is_superuser" or defaults["is_superuser"]
                }
                user = create(email=spec["email"], password=password, **extra)
            else:
                for key, value in defaults.items():
                    setattr(user, key, value)
                user.save(
                    update_fields=[
                        "first_name",
                        "last_name",
                        "role",
                        "is_staff",
                        "is_superuser",
                        "is_active",
                        "updated_at",
                    ]
                )
            users[user.email] = user
        return users

    def _seed_memberships(self, users, company: Company, roles) -> None:
        service = MembershipService()
        assignments = (
            ("james.carter@acme.example.com", UserRole.COMPANY_ADMIN),
            ("priya.shah@acme.example.com", UserRole.MANAGER),
            ("ada.lovelace@acme.example.com", UserRole.EMPLOYEE),
            ("nia.okonkwo@acme.example.com", UserRole.EMPLOYEE),
            ("omar.hassan@acme.example.com", UserRole.EMPLOYEE),
        )
        for email, role_code in assignments:
            service.assign(
                user=users[email],
                company=company,
                role=roles[role_code],
            )

    def _seed_departments(self, company: Company) -> dict[str, Department]:
        departments = {}
        for name, description in DEPARTMENTS:
            department, _created = Department.objects.update_or_create(
                company=company,
                name=name,
                defaults={
                    "description": description,
                    "status": OrgStatus.ACTIVE,
                },
            )
            departments[name] = department
        return departments

    def _seed_positions(
        self,
        company: Company,
        departments: dict[str, Department],
    ) -> dict[str, Position]:
        positions = {}
        for department_name, title, description in POSITIONS:
            position, _created = Position.objects.update_or_create(
                company=company,
                department=departments[department_name],
                title=title,
                defaults={
                    "description": description,
                    "status": OrgStatus.ACTIVE,
                },
            )
            positions[title] = position
        return positions

    def _seed_employees(
        self,
        company: Company,
        users: dict[str, User],
        departments: dict[str, Department],
        positions: dict[str, Position],
    ) -> dict[str, Employee]:
        employees = {}
        for spec in EMPLOYEES:
            user = users[spec["email"]]
            employee, _created = Employee.objects.update_or_create(
                company=company,
                employee_code=spec["employee_code"],
                defaults={
                    "user": user,
                    "first_name": user.first_name,
                    "last_name": user.last_name,
                    "gender": spec["gender"],
                    "date_of_birth": spec["date_of_birth"],
                    "phone": spec["phone"],
                    "address": spec["address"],
                    "emergency_contact_name": spec["emergency_contact_name"],
                    "emergency_contact_relationship": spec[
                        "emergency_contact_relationship"
                    ],
                    "emergency_contact_phone": spec["emergency_contact_phone"],
                    "department": departments[spec["department"]],
                    "position": positions[spec["position"]],
                    "joining_date": spec["joining_date"],
                    "employment_type": spec["employment_type"],
                    "status": spec["status"],
                },
            )
            employees[spec["email"]] = employee
        return employees

    def _assign_managers(
        self,
        departments: dict[str, Department],
        employees: dict[str, Employee],
    ) -> None:
        for spec in EMPLOYEES:
            employee = employees[spec["email"]]
            manager_email = spec["manager_email"]
            manager = employees[manager_email] if manager_email else None
            if employee.manager_id != (manager.id if manager else None):
                employee.manager = manager
                employee.save(update_fields=["manager", "updated_at"])

        for department_name, email in DEPARTMENT_MANAGERS.items():
            department = departments[department_name]
            manager = employees[email]
            if department.manager_id != manager.id:
                department.manager = manager
                department.save(update_fields=["manager", "updated_at"])

    def _seed_records(self, company: Company, users: dict[str, User]) -> None:
        for spec in OWNED_RECORDS:
            assigned = (
                users[spec["assigned_email"]] if spec["assigned_email"] else None
            )
            TenantOwnedRecord.objects.update_or_create(
                company=company,
                title=spec["title"],
                defaults={
                    "visibility": spec["visibility"],
                    "owner": users[spec["owner_email"]],
                    "assigned_to": assigned,
                },
            )
