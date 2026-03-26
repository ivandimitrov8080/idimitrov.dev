INSERT INTO account(name, password) VALUES
  -- password1
  ('user1', '$argon2id$v=19$m=65536,t=2,p=1$zjMGhAEfI+qkznRRLI8yCw$wFOOydEpHpidS/y5e/UQF93vgOzdh+94Y/s9tunpq64'),
  -- password2
  ('user2', '$argon2id$v=19$m=65536,t=2,p=1$ITgHPtt6SKoCmazycRaQlQ$Kd59NJrOmAILIG8sv8tj1VAM+dUhd7SzQBedF24Bh8k'),
  -- password3
  ('user3', '$argon2id$v=19$m=65536,t=2,p=1$fdL8IxeoojZTaJP86UxswQ$6Bauca0QV6HcvVCDNPrHSwyeozp3jJ7DIh2fdeUV6Yo');

INSERT INTO profile(account_id, name, created_at) VALUES
  ((SELECT id FROM account WHERE name = 'user1'), 'User One', now()),
  ((SELECT id FROM account WHERE name = 'user2'), 'User Two', now()),
  ((SELECT id FROM account WHERE name = 'user3'), 'User Three', now());
