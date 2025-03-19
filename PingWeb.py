import asyncio
import time
import socket
from urllib.parse import urlparse
import requests
from .. import loader, utils

@loader.tds
class PingWebsite(loader.Module):
    strings = {
        "name": "PingWebsite",
        "usage": "Использование: .pingweb {веб-сайт или IP}",
        "error": "Ошибка: <code>{error}</code>",
        "result": (
            "<b>Сайт:</b> {url}<br>"
            "<b>IP:</b> {ip}<br>"
            "<b>Status:</b> {status}<br>"
            "<b>Server:</b> {server}<br>"
            "<b>Среднее время отклика:</b> {avg} мс<br>"
            "<b>Запросов отправлено:</b> {count}"
        ),
        "sending": "Запросы отправляются..."
    }

    @loader.command(ru_doc="Проверяет доступность сайта и выводит его характеристики")
    async def pingweb(self, message):
        args = utils.get_args_raw(message).strip()
        if not args:
            return await utils.answer(message, self.strings("usage"))
        await message.edit(self.strings("sending"))
        website = args
        if not website.startswith("http://") and not website.startswith("https://"):
            website = "http://" + website
        num_requests = 5
        times_list = []
        status_code = None
        server = "N/A"
        for _ in range(num_requests):
            try:
                start = time.time()
                response = await asyncio.to_thread(requests.get, website, timeout=5)
                end = time.time()
                elapsed = (end - start) * 1000
                times_list.append(elapsed)
                status_code = response.status_code
                if "Server" in response.headers:
                    server = response.headers["Server"]
            except Exception as e:
                times_list.append(5000)
        avg_time = sum(times_list) / len(times_list)
        parsed_url = urlparse(website)
        domain = parsed_url.netloc
        try:
            ip_address = socket.gethostbyname(domain)
        except Exception as e:
            ip_address = "N/A"
        result_message = self.strings("result").format(
            url=website,
            ip=ip_address,
            status=status_code if status_code else "N/A",
            server=server,
            avg=f"{avg_time:.2f}",
            count=num_requests
        )
        await message.edit(result_message, parse_mode="html")
