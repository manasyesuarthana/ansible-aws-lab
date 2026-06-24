resource "aws_key_pair" "control_key" {
  key_name   = "control-key"
  public_key = file("keys/controlkey.pub")
}

resource "aws_key_pair" "web_key" {
  key_name   = "web-key"
  public_key = file("keys/webkey.pub")
}

resource "aws_key_pair" "db_key" {
  key_name   = "db-key"
  public_key = file("keys/dbkey.pub")
}
