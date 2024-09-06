from django.urls import path
from .views import OCRView, TTSView

urlpatterns = [
    path('ocr/', OCRView.as_view(), name='ocr'),
    path('tts/', TTSView.as_view(), name='tts'),
]
