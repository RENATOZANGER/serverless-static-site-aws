#Create an access control to allow CloudFront to connect to the S3 bucket
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-origin-access-control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  description                       = "Access control for CloudFront to access S3 bucket"
}

locals {
  s3_origin_id = "myS3Origin"
}

#Create a CloudFront distribution to serve content from your S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [aws_s3_bucket.static_site]

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "myS3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  web_acl_id          = null

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  #Limits distribution to specific regions to reduce costs (includes US, Europe, Canada, and Asia).
  price_class = "PriceClass_200"

  tags = {
    Environment = "dev"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#Display cloudfront url in output
output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
