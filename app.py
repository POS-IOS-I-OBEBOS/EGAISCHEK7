import os

from dotenv import load_dotenv
from flask import Flask, render_template, request

import aspose_barcode_cloud

load_dotenv()

app = Flask(__name__)
app.config["SECRET_KEY"] = os.environ.get("FLASK_SECRET_KEY", "change-me")

_recognize_api = None


def _create_recognize_api() -> aspose_barcode_cloud.RecognizeApi:
    client_id = os.environ.get("ASPOSE_CLIENT_ID")
    client_secret = os.environ.get("ASPOSE_CLIENT_SECRET")

    if not client_id or not client_secret:
        raise RuntimeError(
            "ASPOSE_CLIENT_ID and ASPOSE_CLIENT_SECRET environment variables must be set."
        )

    configuration = aspose_barcode_cloud.Configuration()
    configuration.client_id = client_id
    configuration.client_secret = client_secret

    api_client = aspose_barcode_cloud.ApiClient(configuration=configuration)
    return aspose_barcode_cloud.RecognizeApi(api_client)


def get_recognize_api() -> aspose_barcode_cloud.RecognizeApi:
    global _recognize_api
    if _recognize_api is None:
        _recognize_api = _create_recognize_api()
    return _recognize_api


@app.route("/", methods=["GET", "POST"])
def index():
    decoded_values = []
    error_message = None

    if request.method == "POST":
        uploaded_file = request.files.get("image")
        if not uploaded_file or uploaded_file.filename == "":
            error_message = "Пожалуйста, выберите изображение с DataMatrix кодом."
        else:
            try:
                api = get_recognize_api()
                file_bytes = uploaded_file.read()
                if not file_bytes:
                    raise ValueError("Файл не содержит данных.")

                response = api.recognize_multipart(
                    barcode_type=aspose_barcode_cloud.DecodeBarcodeType.DATAMATRIX,
                    file=bytearray(file_bytes),
                    recognition_mode=aspose_barcode_cloud.RecognitionMode.FAST,
                )

                decoded_values = [
                    barcode.barcode_value
                    for barcode in response.barcodes or []
                    if barcode.barcode_value
                ]

                if not decoded_values:
                    error_message = "DataMatrix коды не найдены."
            except RuntimeError as exc:
                error_message = str(exc)
            except aspose_barcode_cloud.ApiException as exc:
                error_message = f"Ошибка сервиса Aspose: {exc}"
            except Exception as exc:  # noqa: BLE001
                error_message = f"Не удалось распознать код: {exc}"

    return render_template(
        "index.html",
        decoded_values=decoded_values,
        error_message=error_message,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=True)
