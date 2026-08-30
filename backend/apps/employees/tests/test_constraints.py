from django.core.exceptions import ValidationError
from django.db import IntegrityError
from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.employees.models import Employee, Position
from apps.employees.tests.fixtures import EMPLOYEES, EmployeeFixtureMixin
from apps.employees.views import DepartmentViewSet, EmployeeViewSet, PositionViewSet


class ConstraintTests(EmployeeFixtureMixin, TestCase):
    def test_duplicate_code_same_company_db(self) -> None:
        with self.assertRaises(ValidationError):
            Employee.objects.create(
                company=self.company_a,
                employee_code="EMP-001",
                first_name="Dup",
                last_name="Code",
            )

    def test_same_code_other_company_ok(self) -> None:
        emp = Employee.objects.create(
            company=self.company_b,
            employee_code="EMP-009",
            first_name="Ok",
            last_name="Beta",
        )
        self.assertEqual(emp.employee_code, "EMP-009")

    def test_self_manager_rejected(self) -> None:
        self.emp_a1.manager = self.emp_a1
        with self.assertRaises(ValidationError):
            self.emp_a1.save()

    def test_self_manager_check_constraint(self) -> None:
        with self.assertRaises(IntegrityError):
            Employee.objects.filter(pk=self.emp_a1.pk).update(
                manager_id=self.emp_a1.pk
            )

    def test_cross_company_manager_rejected(self) -> None:
        self.emp_a1.manager = self.emp_b1
        with self.assertRaises(ValidationError):
            self.emp_a1.save()

    def test_cross_company_position_department_rejected(self) -> None:
        with self.assertRaises(ValidationError):
            Position.objects.create(
                company=self.company_a,
                department=self.dept_b,
                title="Illegal",
            )

    def test_api_self_manager_rejected(self) -> None:
        client = self.authenticate(self.admin_a)
        response = client.patch(
            f"{EMPLOYEES}/{self.emp_a1.id}/",
            {"manager": str(self.emp_a1.id)},
            format="json",
        )
        self.assertEqual(response.status_code, 400)


class QuerysetIsolationTests(EmployeeFixtureMixin, TestCase):
    def _queryset(self, viewset_cls, user):
        factory = APIRequestFactory()
        request = factory.get("/")
        force_authenticate(request, user=user)
        request.user = user
        view = viewset_cls()
        view.action = "list"
        view.request = request
        view.format_kwarg = None
        return view.get_queryset()

    def test_employee_queryset_is_tenant_filtered(self) -> None:
        qs = self._queryset(EmployeeViewSet, self.admin_a)
        self.assertTrue(qs.filter(pk=self.emp_a1.pk).exists())
        self.assertFalse(qs.filter(pk=self.emp_b1.pk).exists())

    def test_manager_queryset_excludes_non_reports(self) -> None:
        qs = self._queryset(EmployeeViewSet, self.manager_a)
        self.assertTrue(qs.filter(pk=self.emp_a1.pk).exists())
        self.assertTrue(qs.filter(pk=self.emp_manager_a.pk).exists())
        self.assertFalse(qs.filter(pk=self.emp_a2.pk).exists())
        self.assertFalse(qs.filter(pk=self.emp_b1.pk).exists())

    def test_employee_queryset_is_self_only(self) -> None:
        qs = self._queryset(EmployeeViewSet, self.employee_a)
        self.assertEqual(list(qs.values_list("pk", flat=True)), [self.emp_a1.pk])

    def test_department_and_position_querysets(self) -> None:
        dept_qs = self._queryset(DepartmentViewSet, self.admin_a)
        pos_qs = self._queryset(PositionViewSet, self.admin_a)
        self.assertTrue(dept_qs.filter(pk=self.dept_a.pk).exists())
        self.assertFalse(dept_qs.filter(pk=self.dept_b.pk).exists())
        self.assertTrue(pos_qs.filter(pk=self.pos_a.pk).exists())
        self.assertFalse(pos_qs.filter(pk=self.pos_b.pk).exists())
