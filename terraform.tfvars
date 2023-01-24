cidrs_pub = {
  pub = "192.168.0.0/24"
}

cidrs_fgsp = {
  fgsp = "192.168.1.0/24"
}

cidrs_prod = {
  prod0 = "10.0.0.0/24"
  prod1 = "10.0.1.0/24"
}

cidrs_comm = {
  comm0 = "10.1.0.0/24"
  comm1 = "10.1.1.0/24"
  comm2 = "10.1.2.0/24"
}

cidrs_test = {
  test0 = "10.100.0.0/24"
}

cidrs_dev = {
  dev0 = "10.200.0.0/24"
}

cidrs_transit = {
  trans0 = "192.168.2.0/24"
}

cidrs_hq = {
  hq0 = "172.16.0.0/16"
}

connected_subnets = [
  "pub", "fgsp", "prod0", "comm0", "test0", "dev0"
]

flexvm_tokens = ["381BA5456FCE46919ECC", "26C0BDF7335B43589591"]

branch_tokens = ["3883D97B9CDA495982CD", "EF14971D86BF4AEAB2E5", "7C8FCD467D5345D7BE82", "0215CD63D050020473E9", "71CA4B29D6FE3A134B24", "D36BA0897AEC0332DFA1", "CEF40F9707A7B818B563", "7A490C7C871425818BBE"]
