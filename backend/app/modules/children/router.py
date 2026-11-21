import logging
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.modules.auth.dependencies import get_current_parent
from app.modules.children.schemas import ChildCreateRequest, ChildUpdateRequest
from app.modules.children.service import (
    create_child,
    get_children,
    update_child,
    delete_child
)


router = APIRouter(
    prefix="/children",
    tags=["Children"]
)

security = HTTPBearer()


@router.post("/")
async def add_child(
    request: ChildCreateRequest,
    current_parent=Depends(get_current_parent),
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        child_data = request.model_dump(mode="json")

        child = create_child(
            access_token=credentials.credentials,
            parent_id=str(current_parent.id),
            child_data=child_data
        )

        if child is None:
            raise HTTPException(
                status_code=500,
                detail="Child profile could not be created."
            )

        return {
            "success": True,
            "message": "Child profile created successfully.",
            "data": child
        }

    except HTTPException:
        raise

    except Exception:
        logging.exception("Child creation failed")
        raise HTTPException(
            status_code=500,
            detail="Unable to create child profile. Check backend logs."
        )
@router.get("/")
async def list_children(
    current_parent=Depends(get_current_parent),
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        children = get_children(
            access_token=credentials.credentials
        )

        return {
            "success": True,
            "message": "Children retrieved successfully.",
            "data": children
        }

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Unable to retrieve children."
        )
@router.put("/{child_id}")
async def edit_child(
    child_id: str,
    request: ChildUpdateRequest,
    current_parent=Depends(get_current_parent),
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        child_data = request.model_dump(
            mode="json",
            exclude_unset=True
        )

        child = update_child(
            access_token=credentials.credentials,
            child_id=child_id,
            child_data=child_data
        )

        if child is None:
            raise HTTPException(
                status_code=404,
                detail="Child not found."
            )

        return {
            "success": True,
            "message": "Child profile updated successfully.",
            "data": child
        }

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Unable to update child profile."
        )
@router.delete("/{child_id}")
async def remove_child(
    child_id: str,
    current_parent=Depends(get_current_parent),
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    try:
        deleted_child = delete_child(
            access_token=credentials.credentials,
            child_id=child_id
        )

        if not deleted_child:
            raise HTTPException(
                status_code=404,
                detail="Child not found."
            )

        return {
            "success": True,
            "message": "Child profile deleted successfully."
        }

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Unable to delete child profile."
        )