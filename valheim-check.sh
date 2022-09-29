#!/usr/bin/env bash
source "Defaults" || exit 1

red='\e[31m\e[1m'
green='\e[32m\e[1m'
yellow='\e[33m\e[1m'
background='\e[40m'
normal='\e[0m'

function checkServer {
  [[ 0 == $(sudo dnf info nmap | grep -c 'Installed Packages') ]] && sudo dnf install -yq nmap
  if [[ 1 == $(sudo /usr/bin/env nmap -Pn -sU "${HOST}" -p U:2456 | grep -c 'open') ]]; then
    echo -e "${green}⬢${normal} ${background}[ ${green}Success${normal}${background}: ${CONTAINER_NAME} open on UDP port 2456 ${normal}${background}]${normal}"
  else
    echo -e "${yellow}⬢${normal} ${background}[ ${yellow}Warning${normal}${background}: ${CONTAINER_NAME} not open on UDP port 2456 ${normal}${background}]${normal}"
  fi
  if [[ 1 == $(sudo /usr/bin/env nmap -Pn "${HOST}" -p 2456 | grep -c 'open') ]]; then
    echo -e "${green}⬢${normal} ${background}[ ${green}Success${normal}${background}: ${CONTAINER_NAME} open on TCP port 2456 ${normal}${background}]${normal}"
  else
    echo -e "${yellow}⬢${normal} ${background}[ ${yellow}Warning${normal}${background}: ${CONTAINER_NAME} not open on TCP port 2456 ${normal}${background}]${normal}"
  fi
  if [[ 0 == $(sudo /usr/bin/env nmap -Pn -sU "${HOST}" -p U:2456 | grep -c 'open') && 0 == $(sudo /usr/bin/env nmap -Pn "${HOST}" -p 2456 | grep -c 'open') ]]; then
    echo -e "${red}⬢${normal} ${background}[ ${red}Failure${normal}${background}: ${CONTAINER_NAME} not open on any ports. ${normal}${background}]${normal}"
    return 1
  fi
  return 0
}

checkServer

exit $?
