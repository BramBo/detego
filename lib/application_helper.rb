# Make sure a domain/service has a valid name so it can get create by any OS(eg. Windows)
def valid_directory_name name
  return name.match(/^[a-z0-9\_\.\-]+$/i)
end