resource "aws_dynamodb_table" "students" {
  name         = "studentData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "studentid"

  attribute {
    name = "studentid"
    type = "S"
  }
}
