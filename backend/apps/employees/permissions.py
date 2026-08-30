"""Employee endpoints use apps.common.permissions.

Organization (department/position) writes use settings.manage so a
MANAGER with employees.update cannot rename the org chart.
"""

ORGANIZATION_WRITE_PERMISSION = "settings.manage"
