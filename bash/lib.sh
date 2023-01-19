# This is a base template for a bash lib file.

# colors
bash_lib_define_colors ()
{
	if [[ -z $NO_COLOR ]]; then
		RED='\033[0;31m'
		GREEN='\033[0;32m'
		YELLOW='\033[0;33m'
		BLUE='\033[0;34m'
		PURPLE='\033[0;35m'
		CYAN='\033[0;36m'
		WHITE='\033[0;37m'
		NC='\033[0m' # No Color
	else
		RED=''
		GREEN=''
		YELLOW=''
		BLUE=''
		PURPLE=''
		CYAN=''
		WHITE=''
		NC=''
	fi
	MSG_COLOR=$BLUE
	OK_COLOR=$GREEN
	ERROR_COLOR=$RED
	WARNING_COLOR=$YELLOW
}
bash_lib_define_colors


# @brief echo the script's dir (symlink safe way)
# @usage script_dir=$(find_script_dir)
find_script_dir ()
{
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		SOURCE="$(readlink "$SOURCE")"
		[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	echo "$DIR"
}

# @brief echo the script's dir (doesn't follow symlinks)
# @usage script_dir=$(find_script_dir_unsafe)
find_script_dir_unsafe ()
{
	echo "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
}

# @brief echo the given text as a message
# @param $1 the text to echo
echo_msg ()
{
	echo -e "[ ${MSG_COLOR}MSG${NC} ] $1"
}

# @brief echo the given text as an ok message
# @param $1 the text to echo
echo_ok_msg ()
{
	echo -e "[ ${OK_COLOR}OK${NC}  ] $1"
}

# @brief echo the given text as a warning message
# @param $1 the text to echo
echo_warning_msg ()
{
	echo -e "[ ${WARNING_COLOR}WAR${NC} ] $1"
}

# @brief echo the given text as an error message
# @param $1 the text to echo
echo_error_msg ()
{
	echo -e "[ ${ERROR_COLOR}ERR${NC} ] $1"
}

# @brief waits until any key is pressed
# @param $1 the text to echo (optional)
wait_for_any_key_press ()
{
	read -n 1 -s -r -p "$1"
	echo
}

# @brief gets time zone in localtime format for symlinking
# @return timezone (e.g Asia/Jerusalem)
get_timezone ()
{
	echo $(curl -s https://ipapi.co/timezone)
}

# @brief sets a symlink for the /etc/localtime for the timezone file returned from 'get_timezone'
set_timezone ()
{
	ln -sf /usr/share/zoneinfo/$(get_timezone) /etc/localtime
}

# @brief check if the given command exists
# @param $1 the command to check
# @return 0 if the command exists, 1 otherwise
does_command_exist ()
{
	hash "$1" > /dev/null 2>&1
}

# @brief prints the git branch name
# @usage branch=$(get_git_branch)
get_git_branch ()
{
	#git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
	local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
	# check if branch is an empty string
	if [ ! -z "$branch" ]; then
		printf "$branch"
	fi
}

# @brief echo the full path of a given path
# @param $1 path to the file
get_full_path ()
{
	cd $(dirname $1)
	echo "$PWD/$(basename $1)"
	cd $OLDPWD
}

# @brief archive extraction
# @usage extract <file>
extract ()
{
	if [ -f "$1" ] ; then
		case $1 in
			*.tar.bz2)   tar xjf $1   ;;
			*.tar.gz)    tar xzf $1   ;;
			*.bz2)       bunzip2 $1   ;;
			*.rar)       unrar x $1   ;;
			*.gz)        gunzip $1    ;;
			*.tar)       tar xf $1    ;;
			*.tbz2)      tar xjf $1   ;;
			*.tgz)       tar xzf $1   ;;
			*.zip)       unzip $1     ;;
			*.Z)         uncompress $1;;
			*.7z)        7z x $1      ;;
			*.deb)       ar x $1      ;;
			*.tar.xz)    tar xf $1    ;;
			*.tar.zst)   unzstd $1    ;;
			*)           echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
	echo "'$1' is not a valid file"
	echo "usage: extract <file>"
	fi
}

# @brief prints the content of a yaml file in a way that eval can use it
# @brief to use it, just eval the output of this function
# @param $1 the path to the yaml file
# @param $2 a prefix to add to the variable names (optional)
# @example
# ```yaml
# catagory:
#   key: value
# ```
# will set:
# $catagory_key = value
# @usage eval $(parse_yaml $file)
parse_yaml ()
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s='\'%s\''\n", "'$prefix'",vn, $2, $3);
      }
   }'
}
