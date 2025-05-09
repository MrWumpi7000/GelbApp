import flet as ft # type: ignore
import requests
import json 

def register_page(page: ft.Page):
    page.clean()
    page.title = "Register Page"
    page.theme_mode = ft.ThemeMode.LIGHT 

    # UI components
    username_field = ft.TextField(label="Username")
    email_field = ft.TextField(label="Email")
    password_field = ft.TextField(label="Password", password=True, can_reveal_password=True)
    
    # Create an info text label
    info_label = ft.Text("", theme_style=ft.TextThemeStyle.TITLE_SMALL)

    # Function to handle registration
    def register(e):
        username = username_field.value.strip()
        password = password_field.value.strip()
        email = email_field.value.strip()
        
        # Validate input
        if not username or not username or not password or not email:
            info_label.value = "Please fill in all fields"
            info_label.color = "red"
            page.update()
            return
        try:
            url = "http://awesom-o.org:8000/register"
            headers = {
                "accept": "application/json",
                "Content-Type": "application/json"
            }
            data = {
                "username": username,
                "email": email,
                "password": password,
            }

            response = requests.post(url, headers=headers, data=json.dumps(data))


            if response.status_code == 200:
                session_id = response.json().get("session_id")
                username = response.json().get("username")
                page.session.set("access_token", session_id)
                page.session.set("username", username)
                page.go("/")
            
            
            else:
                error_message = response.json().get("detail", "Registration failed")
                info_label.value = error_message
                info_label.color = "red"
        except requests.exceptions.RequestException as e:
            info_label.value = f"An error occurred: {str(e)}"
            info_label.color = "red"

        page.update()

    page.add(
        ft.Text("GelbApp", size=30, color=ft.colors.YELLOW_900, weight=ft.FontWeight.BOLD),
        ft.Text("Register", size=23, weight=ft.FontWeight.BOLD),
        username_field,
        email_field,
        password_field,
        ft.ElevatedButton("Register", on_click=register),
        info_label,  # Add the info label to the page
        ft.TextButton("Allready have an Account", on_click=lambda _: page.go("/login"))  # Link to login
    )

# You can run the registration page separately or as part of your main app.
if __name__ == "__main__":
    ft.app(target=register_page, view=ft.AppView.WEB_BROWSER)
