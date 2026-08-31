from django.core.management.base import BaseCommand, CommandError

from apps.companies.models import Company
from apps.leave.services import LeaveService


class Command(BaseCommand):
    help = (
        "Create missing leave balances for a calendar year. "
        "Does not overwrite existing rows."
    )

    def add_arguments(self, parser):
        parser.add_argument("--year", type=int, required=True)
        parser.add_argument(
            "--company",
            dest="company_slug",
            default="",
            help="Optional company slug. Default: all companies.",
        )

    def handle(self, *args, **options):
        year = options["year"]
        if year < 2000 or year > 2100:
            raise CommandError("year must be a four-digit calendar year.")
        slug = (options.get("company_slug") or "").strip()
        companies = Company.objects.filter(is_active=True)
        if slug:
            companies = companies.filter(slug=slug)
            if not companies.exists():
                raise CommandError(f"Unknown company slug: {slug}")
        service = LeaveService()
        total = 0
        for company in companies:
            created = service.ensure_balances_for_year(company=company, year=year)
            total += created
            self.stdout.write(f"{company.slug}: created {created} balance(s)")
        self.stdout.write(self.style.SUCCESS(f"Created {total} leave balance(s)."))
