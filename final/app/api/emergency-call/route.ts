import { NextResponse } from 'next/server';
import twilio from 'twilio';

export async function POST(req: Request) {
  const body = await req.json() as { to?: string; contactName?: string };
  const { to, contactName } = body;

  if (!to || typeof to !== 'string') {
    return NextResponse.json({ error: 'Missing or invalid phone number' }, { status: 400 });
  }

  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken  = process.env.TWILIO_AUTH_TOKEN;
  const from       = process.env.TWILIO_FROM_NUMBER;

  if (!accountSid || !authToken || !from) {
    console.error('[emergency-call] Twilio env vars not configured');
    return NextResponse.json({ error: 'Twilio not configured on server' }, { status: 500 });
  }

  const name   = contactName ? contactName.replace(/[<>&"]/g, '') : 'the rider';
  const twiml  = `<Response>
    <Say voice="alice" language="en-US">
      This is an automated emergency alert from Cycle Watch.
      ${name} has been detected in a possible crash and has not dismissed the safety alert.
      Please check on them immediately and contact emergency services if needed.
    </Say>
    <Pause length="1"/>
    <Say voice="alice" language="en-US">
      Repeating — this is an automated emergency alert from Cycle Watch.
      Please check on ${name} immediately.
    </Say>
  </Response>`;

  try {
    const client = twilio(accountSid, authToken);
    await client.calls.create({ twiml, to, from });
    return NextResponse.json({ success: true });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    console.error('[emergency-call] Twilio error:', message);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
