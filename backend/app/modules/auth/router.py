import logging
from fastapi import APIRouter, HTTPException, Depends
from supabase_auth.errors import AuthApiError

from app.modules.auth.schemas import RegisterRequest, LoginRequest
from app.modules.auth.service import register_parent, login_parent
from app.modules.auth.dependencies import get_current_parent

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


@router.post("/register")
async def register(request: RegisterRequest):
    try:
        response = register_parent(
            email=request.email,
            password=request.password
        )

        user = response.user

        if user is None:
            raise HTTPException(
                status_code=400,
                detail="Registration could not be completed."
            )

        return {
            "success": True,
            "message": "Registration successful. Please verify your email.",
            "data": {
                "user_id": str(user.id),
                "email": user.email,
                "email_verification_required": response.session is None
            }
        }

    except AuthApiError as e:
        logging.exception("Supabase registration error: %s", e)
        raise HTTPException(
            status_code=400,
            detail="Registration failed. Check backend logs for the actual error."
        )


@router.post("/login")
async def login(request: LoginRequest):
    try:
        response = login_parent(
            email=request.email,
            password=request.password
        )

        user = response.user
        session = response.session

        if user is None or session is None:
            raise HTTPException(
                status_code=401,
                detail="Login failed."
            )

        return {
            "success": True,
            "message": "Login successful.",
            "data": {
                "user_id": str(user.id),
                "email": user.email,
                "access_token": session.access_token,
                "refresh_token": session.refresh_token,
                "token_type": "bearer",
                "expires_in": session.expires_in
            }
        }

    except AuthApiError:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password, or email confirmation is required."
        )

@router.get("/me")
async def get_my_profile(
    current_parent=Depends(get_current_parent)
):
    return {
        "success": True,
        "message": "Authenticated parent verified successfully.",
        "data": {
            "user_id": str(current_parent.id),
            "email": current_parent.email
        }
    }
