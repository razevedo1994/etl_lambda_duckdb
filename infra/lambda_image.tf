resource "docker_image" "duck" {
    name = "python-duckdb:latest"
    build {
        context = "./app"
        dockerfile = "Dockerfile"
    }
    triggers = {
        dir_checksum = filechecksum("md5", "./app/Dockerfile")
    }
}