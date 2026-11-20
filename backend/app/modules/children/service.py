from supabase import create_client

from app.config import settings


def get_parent_supabase_client(access_token: str):
    """
    Create a Supabase client using the logged-in parent's JWT.
    This ensures database queries are subject to RLS policies.
    """

    client = create_client(
        settings.SUPABASE_URL,
        settings.SUPABASE_KEY
    )

    client.postgrest.auth(access_token)

    return client
def create_child(
    access_token: str,
    parent_id: str,
    child_data: dict
):
    client = get_parent_supabase_client(access_token)

    child_data["parent_id"] = parent_id

    response = (
        client.table("children")
        .insert(child_data)
        .execute()
    )

    return response.data[0] if response.data else None

def get_children(access_token: str):
    client = get_parent_supabase_client(access_token)

    response = (
        client.table("children")
        .select("*")
        .order("created_at", desc=True)
        .execute()
    )

    return response.data
def update_child(
    access_token: str,
    child_id: str,
    child_data: dict
):
    client = get_parent_supabase_client(access_token)

    response = (
        client.table("children")
        .update(child_data)
        .eq("id", child_id)
        .execute()
    )

    return response.data[0] if response.data else None
def delete_child(
    access_token: str,
    child_id: str
):
    client = get_parent_supabase_client(access_token)

    response = (
        client.table("children")
        .delete()
        .eq("id", child_id)
        .execute()
    )

    return response.data