#!/usr/bin/env python3
"""Sert le build web avec repli sur index.html, pour les liens profonds.

`python3 -m http.server` répond 404 à `/plants/…` ; l'app a besoin que
toute adresse renvoie la page d'accueil, comme le ferait un hébergeur.

Usage : serve.py [port] [dossier]   (défauts : 8081, build/web)
"""
import http.server
import os
import socketserver
import sys

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
root = sys.argv[2] if len(sys.argv) > 2 else 'build/web'
os.chdir(root)


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path) or os.path.isdir(path) and not os.path.exists(os.path.join(path, 'index.html')):
            self.path = '/index.html'
        return super().do_GET()

    def log_message(self, *args):
        pass


socketserver.TCPServer.allow_reuse_address = True
socketserver.TCPServer(('', port), Handler).serve_forever()
