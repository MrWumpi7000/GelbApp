import flet as ft # type: ignore
from urllib.parse import urlparse, parse_qs
from pages.main_page import main_page  # Import main page function
from pages.login_page import login_page  # Import login page function
from pages.register_page import register_page  # Import register page function

# Define your routes
ROUTES = {
    "/": main_page,
    "/login": login_page,
    "/register": register_page,
}

def main(page: ft.Page):
    def route_change(e: ft.RouteChangeEvent):
        page.clean()
        parsed_url = urlparse(e.route)  # Parse the route
        query_params = parse_qs(parsed_url.query)  # Extract query parameters
        
        render_function = ROUTES.get(parsed_url.path, main_page)
        render_function(page)

    page.on_route_change = route_change
    page.go(page.route)
    
if __name__ == "__main__":
    ft.app(target=main, view=ft.AppView.WEB_BROWSER, port=9000)