db = db.getSiblingDB('somedb');
for (var i = 0; i < 2000; i++) {
    db.helloDoc.insertOne({ age: i, name: 'ly' + i });
}
