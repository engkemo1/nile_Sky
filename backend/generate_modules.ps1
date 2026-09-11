$modules = @("config", "auth", "users", "operators", "packages", "flights", "flights/flight-templates", "bookings", "payments", "balloons", "pilots", "drivers", "reviews", "notifications", "coupons", "weather", "analytics", "upload", "i18n")

foreach ($module in $modules) {
    Write-Host "Generating module: $module"
    npx nest g module $module --no-spec
    npx nest g controller $module --no-spec
    npx nest g service $module --no-spec
}
