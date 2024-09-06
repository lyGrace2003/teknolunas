from django.http import JsonResponse
from django.shortcuts import render
from gtts import gTTS
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from PIL import Image
import numpy as np
import pytesseract
import io
import os
import base64

# Set the Tesseract executable path (adjust for your environment)
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

class OCRView(APIView):
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)

        image_file = request.FILES['image']

        try:
            # Read image bytes and convert to PIL Image
            image_pil = Image.open(io.BytesIO(image_file.read()))

            # Ensure the image is in a compatible mode (e.g., RGB)
            if image_pil.mode != 'RGB':
                image_pil = image_pil.convert('RGB')

            # Convert PIL Image to numpy array
            image_np = np.array(image_pil)

            # Perform OCR with Tesseract
            text = pytesseract.image_to_string(image_np)

            # Check if text was detected
            if not text.strip():
                return Response({'text': 'No text detected in the image.'}, status=status.HTTP_200_OK)

            return Response({'text': text}, status=status.HTTP_200_OK)

        except Exception as e:
            # Log the exception
            print(f"Error during OCR processing: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class TTSView(APIView):
    def post(self, request):
        text = request.data.get('text')
        if not text:
            return Response({'error': 'No text provided'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Limit the length of text for TTS processing
            if len(text) > 5000:
                return Response({'error': 'Text too long for TTS processing'}, status=status.HTTP_400_BAD_REQUEST)

            # Create TTS object and save to a file
            tts = gTTS(text)
            temp_file_path = 'temp.mp3'
            tts.save(temp_file_path)

            # Read the saved file and encode it in base64
            with open(temp_file_path, 'rb') as audio_file:
                audio_base64 = base64.b64encode(audio_file.read()).decode()

            # Clean up the temporary file
            os.remove(temp_file_path)

            return JsonResponse({
                'audio': audio_base64,
                'filename': 'output.mp3'
            })

        except Exception as e:
            # Log the exception
            print(f"Error during TTS processing: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
