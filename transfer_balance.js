const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function transferBalance() {
  const superbqRef = db.collection('siqowwam_users').doc('CLYqp2oRxmQU6V8wBUwA11O3F252');
  const yusufRef = db.collection('siqowwam_users').doc('UD3BwTkcjVXVONg1k3TVTjPZ7mN2');
  
  const batch = db.batch();
  
  // Set superbq balance to 0
  batch.update(superbqRef, { balance: 0 });
  
  // Set yusuf balance to 20000
  batch.update(yusufRef, { balance: 20000 });
  
  await batch.commit();
  console.log('Balance transferred from superbq to yusuf!');
  process.exit(0);
}

transferBalance().catch(console.error);
