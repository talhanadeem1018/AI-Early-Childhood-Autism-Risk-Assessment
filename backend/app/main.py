
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.modules.children.router import router as children_router
from app.modules.auth.router import router as auth_router

from app.config import settings

from app.modules.assessment.router import router as assessment_router

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="Backend API for Module 1: Developmental and Early Autism Risk Assessment System."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(
    assessment_router,
    prefix=settings.API_PREFIX
)

app.include_router(
    auth_router,
    prefix=settings.API_PREFIX
)
app.include_router(
    children_router,
    prefix=settings.API_PREFIX
)
@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "ok",
        "service": settings.APP_NAME
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": "Early Childhood Assessment API is running",
        "docs": "/docs"
    }
