
from app.supabase_client import supabase


def register_parent(email: str, password: str):
    response = supabase.auth.sign_up({
        "email": email,
        "password": password
    })

    return response


def login_parent(email: str, password: str):
    response = supabase.auth.sign_in_with_password({
        "email": email,
        "password": password
    })

    return response
