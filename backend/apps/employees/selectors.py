from apps.employees.models import Employee


def employee_queryset():
    return Employee.objects.select_related(
        "user",
        "department",
        "position",
        "manager",
        "company",
    )


def department_queryset():
    from apps.employees.models import Department

    return Department.objects.select_related("manager", "company")


def position_queryset():
    from apps.employees.models import Position

    return Position.objects.select_related("department", "company")


def employee_for_user(*, user, company):
    if user is None or company is None:
        return None
    return employee_queryset().filter(company=company, user=user).first()
