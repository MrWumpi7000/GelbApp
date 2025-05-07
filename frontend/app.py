import flet as ft

def main(page: ft.Page):
    page.title = "Flet Frontend"
    page.add(ft.Text("Hello from Flet!"))

ft.app(target=main)
