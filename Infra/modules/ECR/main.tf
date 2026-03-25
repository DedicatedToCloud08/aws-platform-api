resource "aws_ecr_repository" "ecr" {
  name = "${var.name_prefix}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete = true   

  image_scanning_configuration {
    scan_on_push = true
  }

tags = {
  Name = "${var.name_prefix}-repo"
}
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle" {
  repository = aws_ecr_repository.ecr.name
  policy = jsonencode({
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire images older than 10 days",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
})

}

