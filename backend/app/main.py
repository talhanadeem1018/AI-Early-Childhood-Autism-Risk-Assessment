from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import config
from app.modules.assessment.router import router as assessment_router

app = FastAPI(
    title=config.APP_NAME,
    version="0.1.0",
    description="Backend for the Early Development Assistant FYP (Module 1: Developmental Assessment).",
)

# Open CORS for development (Flutter web / emulators). Restrict before deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "service": config.APP_NAME}


app.include_router(assessment_router, prefix=config.API_PREFIX)
