BEGIN;

ALTER TABLE "Sms" ADD COLUMN userRef INTEGER;

ALTER TABLE "Sms"
  ADD CONSTRAINT "Sms_userRef_fkey" FOREIGN KEY (userRef)
  REFERENCES "usermetatbl";

COMMIT;
