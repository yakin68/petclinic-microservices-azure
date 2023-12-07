region                  = "northeurope"     # Azure bölgesini uygun bir şekilde güncelleyin
instance_type           = "Standard_DS2_v3" # Sanal makine boyutunu uygun bir şekilde güncelleyin
sec-gr-mutual-ports     = [2379, 2380, 10250]
sec-gr-k8s-worker-ports = [22, 30000-32767]
sec-gr-k8s-master-ports = [22,6443,10257,10259,30000-32767]