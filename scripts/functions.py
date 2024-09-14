import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

from pathlib import Path

# Use the application default credentials
cred = credentials.Certificate(Path.cwd().parent / "cbc-attendance-2a7d9-5be9fa91c606.json")
firebase_admin.initialize_app(cred)

# initialize db
db = firestore.client()

def addTicket(name):
	ticket = db.collection("tickets").document()
	ticket.set({"name": name, "regular": name in regular, "hidden": False})
	ticketId = ticket.id
	
	for event in db.collection("events").stream():
		attendance = event.reference.collection("attendees").document(ticketId)
		attendance.set({"checked": False})

def loadCSV(filename):
	with open(filename) as f:
		for line in f:
			addTicket(line.strip())

for ticket in db.collection("tickets").stream():
	print(ticket.to_dict())
	data = ticket.to_dict()
	newData = {'name': data['name'], 'regular': data['regular'], 'active': True}
	if 'hidden' in data:
		ticket.reference.set(newData)