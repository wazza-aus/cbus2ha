# https://github.com/eclipse/paho.mqtt.python/blob/master/examples/loop_asyncio.py
import asyncio
import logging

logger = logging.getLogger(__name__)


class AsyncioHelper:
    def __init__(self, loop, client):
        self.loop = loop
        self.client = client
        self.client.on_socket_open = self.on_socket_open
        self.client.on_socket_close = self.on_socket_close
        self.client.on_socket_register_write = self.on_socket_register_write
        self.client.on_socket_unregister_write = self.on_socket_unregister_write
        self.misc = None

    def on_socket_open(self, client, userdata, sock):
        try:
            self.loop.add_reader(sock, client.loop_read)
        except (RuntimeError, ValueError, OSError) as err:
            logger.warning("Could not watch MQTT socket for reads: %s", err)
        # Keep one housekeeping task for the life of the process. Cancelling it
        # when the socket closes is what used to stop reconnects from running.
        if self.misc is None or self.misc.done():
            self.misc = self.loop.create_task(self.misc_loop())

    def on_socket_close(self, client, userdata, sock):
        self._remove_sock_handler(self.loop.remove_reader, sock)
        self._remove_sock_handler(self.loop.remove_writer, sock)

    def on_socket_register_write(self, client, userdata, sock):
        try:
            self.loop.add_writer(sock, client.loop_write)
        except (RuntimeError, ValueError, OSError) as err:
            logger.warning("Could not watch MQTT socket for writes: %s", err)

    def on_socket_unregister_write(self, client, userdata, sock):
        self._remove_sock_handler(self.loop.remove_writer, sock)

    @staticmethod
    def _remove_sock_handler(remove, sock):
        try:
            remove(sock)
        except (RuntimeError, ValueError, OSError, KeyError):
            pass

    async def misc_loop(self):
        """Call loop_misc() until the process shuts down.

        loop_misc() returns MQTT_ERR_NO_CONN while the broker socket is gone.
        That is expected during a retry window, so it must not end this task.
        """
        while True:
            try:
                self.client.loop_misc()
            except Exception:
                logger.exception("MQTT housekeeping failed")
            try:
                await asyncio.sleep(1)
            except asyncio.CancelledError:
                break
