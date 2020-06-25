

terraform {
  required_version = ">= 0.12"

  backend "gcs" {
      bucket  = "mca-cd-terraform-state"
  }
}


## Se necesita la variable de entorno GOOGLE_CREDENTIALS con el json de credenciales para poder ejecutar
provider "google" {
  project     = "master-cloud-apps-cd"
  region      = "us-east1"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Compute Engine instance
resource "google_compute_instance" "default" {
 name         = "mca-cd-${random_id.instance_id.hex}"
 machine_type = "n1-standard-1"
 zone         = "us-east1-b"
 allow_stopping_for_update = true

 boot_disk {
   initialize_params {
     image = "ubuntu-1804-lts"
   }
 }

// Make sure microk8s is installed
 metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq; sudo snap install microk8s --classic; sudo usermod -a -G microk8s $(whoami); sudo chown -f -R $(whoami) ~/.kube"

 network_interface {
   network = google_compute_network.mca-net.name

   access_config {
     // Include this section to give the VM an external ip address
     nat_ip = google_compute_address.static.address
   }
 }
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

resource "google_compute_firewall" "mca-fw" {
  name    = "mca-firewall"
  network = google_compute_network.mca-net.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080", "443"]
  }
}

resource "google_compute_network" "mca-net" {
  name = "mca-network"
}

output "public-ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
