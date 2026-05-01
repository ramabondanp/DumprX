#!/bin/bash

# Clear Screen
tput reset 2>/dev/null || clear

# Unset Every Variables That We Are Gonna Use Later
unset PROJECT_DIR INPUTDIR UTILSDIR OUTDIR WORK_TMPDIR FILEPATH FILE EXTENSION UNZIP_DIR ArcPath

# Resize Terminal Window To Atleast 30x90 For Better View
printf "\033[8;30;90t" || true

# Banner
function __bannerTop() {
	local GREEN='\033[0;32m'
	local NC='\033[0m'
	echo -e \
	${GREEN}"
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
	"${NC}
}

# Usage/Help
function _usage() {
	printf "  \e[1;32;40m \u2730 Usage: \$ %s [OPTIONS] <Firmware File/Extracted Folder -OR- Supported Website Link> \e[0m\n" "${0}"
	printf "\t\e[1;32m -> Firmware File: The .zip/.rar/.7z/.tar/.bin/.ozip/.kdz etc. file \e[0m\n"
	printf "\t\e[1;32m -> OPTIONS: \e[0m\n"
	printf "\t   -p, --push-only             Push only (Skip extraction)\n"
	printf "\t   -r, --readme-only           Generate README.md only (Skip extraction)\n"
	printf "\t   -m, --mode <local|gitlab>   Choose output mode (default: local)\n"
	printf "\t   -g, --gitlab                Shortcut for --mode gitlab\n"
	printf "\t   -l, --local                 Shortcut for --mode local\n"
	printf "\t   -h, --help                  Show this help and exit\n\n"

	printf " \e[1;34m >> Supported Websites: \e[0m\n"
	printf "\e[36m\t1. Directly Accessible Download Link From Any Website\n"
	printf "\t2. Filehosters like - mega.nz | mediafire | gdrive | onedrive | androidfilehost\e[0m\n"
	printf "\t\e[33m >> Must Wrap Website Link Inside Single-quotes ('')\e[0m\n"

	printf " \e[1;34m >> Supported File Formats For Direct Operation:\e[0m\n"
	printf "\t\e[36m *.zip | *.rar | *.7z | *.tar | *.tar.gz | *.tgz | *.tar.md5\n"
	printf "\t *.ozip | *.ofp | *.ops | *.kdz | ruu_*exe\n"
	printf "\t system.new.dat | system.new.dat.br | system.new.dat.xz\n"
	printf "\t system.new.img | system.img | system-sign.img | UPDATE.APP\n"
	printf "\t *.emmc.img | *.img.ext4 | system.bin | system-p | payload.bin\n"
	printf "\t *.nb0 | .*chunk* | *.pac | *super*.img | *system*.sin\e[0m\n\n"
}

# Welcome Banner
printf "\e[32m" && __bannerTop && printf "\e[0m"

# Parse CLI options
MODE="gitlab"
PUSH_ONLY=false
README_ONLY=false
while [[ $# -gt 0 ]]; do
	case "$1" in
		-p|--push-only)
			PUSH_ONLY=true; shift ;;
		-r|--readme-only)
			README_ONLY=true; shift ;;
		-m|--mode)
			MODE="$2"; shift 2 ;;
		-g|--gitlab)
			MODE="gitlab"; shift ;;
		-l|--local)
			MODE="local"; shift ;;
		-h|--help)
			_usage; exit 0 ;;
		--)
			shift; break ;;
		-*)
			printf "\n  \e[1;31;40m Unknown option: %s \e[0m\n\n" "$1" ; _usage ; exit 1 ;;
		*)
			break ;;
	 esac
done

# Function Input Check (post-option parsing)
if [[ "${PUSH_ONLY}" == "false" && "${README_ONLY}" == "false" ]]; then
	if [[ $# -lt 1 ]]; then
		printf "\n  \e[1;31;40m \u2620 Error: No Input Is Given.\e[0m\n\n"
		_usage && exit 1
	elif [[ -z "${1}" ]]; then
		printf "\n  \e[1;31;40m ! BRUH: Enter Firmware Path.\e[0m\n\n"
		_usage && exit 1
	elif [[ ${#@} -gt 1 ]]; then
		printf "\n  \e[1;31;40m ! BRUH: Enter Only Firmware File Path.\e[0m\n\n"
		_usage && exit 1
	else
		_usage			# Output Usage By Default
	fi
fi

# Set Base Project Directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
if echo "${PROJECT_DIR}" | grep " "; then
	printf "\nProject Directory Path Contains Empty Space,\nPlace The Script In A Proper UNIX-Formatted Folder\n\n"
	exit 1
fi

# Source environment variables from .dumprxenv
source "${PROJECT_DIR}"/.dumprxenv

# Cleanup trap — prevent disk space leaks on unexpected exit
cleanup() {
	if [[ -n "${WORK_TMPDIR:-}" && -d "${WORK_TMPDIR}" ]]; then
		rm -rf "${WORK_TMPDIR}"
	fi
}
trap cleanup EXIT

# Helper: Move downloaded file or copy local file to WORK_TMPDIR
stage_input_file() {
	mv -f "${INPUTDIR}"/"${FILE}" "${WORK_TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${WORK_TMPDIR}"/"${FILE}"
}

# Helper: Clear input dir, move content, and re-invoke the script
reload_and_rerun() {
	local reload_target="${1:-${PROJECT_DIR}/input/}"
	local fallback="${2:-}"
	cd "${PROJECT_DIR}"/ || exit
	if [[ -n "${fallback}" ]]; then
		( bash "${0}" --mode "${MODE}" "${reload_target}" 2>/dev/null || bash "${0}" --mode "${MODE}" "${fallback}" ) || exit 1
	else
		( bash "${0}" --mode "${MODE}" "${reload_target}" ) || exit 1
	fi
	exit
}

# Helper: Reset input directory
reset_inputdir() {
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf "${INPUTDIR:?}"/* 2>/dev/null
}

# Helper: Get first matching property value from build.prop files
# Usage: prop_get "key1:glob1 glob2" "key2:glob3" ...
# Each argument is "property.key:file_glob [file_glob ...]"
# Returns the first non-empty match and stops searching.
prop_get() {
	local entry key files result
	for entry in "$@"; do
		key="${entry%%:*}"
		files="${entry#*:}"
		# Use eval to expand brace/glob patterns in file paths
		result=$(eval "grep -m1 -oP '(?<=^${key}=).*' -hs ${files} 2>/dev/null" | head -1)
		if [[ -n "${result}" ]]; then
			printf '%s' "${result}"
			return 0
		fi
	done
	return 1
}

# Helper: Override variable only if a new value is found
# Usage: prop_override varname "key:files" ...
prop_override() {
	local varname="$1"; shift
	local new_val
	new_val=$(prop_get "$@")
	if [[ -n "${new_val}" ]]; then
		eval "${varname}=\"\${new_val}\""
	fi
}

# Sanitize And Generate Folders
INPUTDIR="${PROJECT_DIR}"/input		# Firmware Download/Preload Directory
UTILSDIR="${PROJECT_DIR}"/utils		# Contains Supportive Programs
OUTDIR=/tmp/out			# Contains Final Extracted Files
WORK_TMPDIR="${OUTDIR}"/tmp			# Temporary Working Directory

if [[ "${PUSH_ONLY}" == "false" && "${README_ONLY}" == "false" ]]; then
	rm -rf "${WORK_TMPDIR}" 2>/dev/null
	mkdir -p "${OUTDIR}" "${WORK_TMPDIR}" 2>/dev/null

	EXTERNAL_TOOLS=(
		bkerler/oppo_ozip_decrypt
		bkerler/oppo_decrypt
		marin-m/vmlinux-to-elf
		ShivamKumarJha/android_tools
		HemanthJabalpuri/pacextractor
	)

	for tool_slug in "${EXTERNAL_TOOLS[@]}"; do
		(
			if ! [[ -d "${UTILSDIR}"/"${tool_slug#*/}" ]]; then
				git clone -q https://github.com/"${tool_slug}".git "${UTILSDIR}"/"${tool_slug#*/}"
			else
				git -C "${UTILSDIR}"/"${tool_slug#*/}" pull -q
			fi
		) &
	done
	wait  # Wait for all parallel git operations to complete

	## See README.md File For Program Credits
	# Set Utility Program Alias
	SDAT2IMG="${UTILSDIR}"/sdat2img.py
	SIMG2IMG="${UTILSDIR}"/bin/simg2img
	PACKSPARSEIMG="${UTILSDIR}"/bin/packsparseimg
	UNSIN="${UTILSDIR}"/unsin
	PAYLOAD_EXTRACTOR="${UTILSDIR}"/bin/payload-dumper-go
	DTC="${UTILSDIR}"/dtc
	VMLINUX2ELF="${UTILSDIR}"/vmlinux-to-elf/vmlinux-to-elf
	KALLSYMS_FINDER="${UTILSDIR}"/vmlinux-to-elf/kallsyms-finder
	OZIPDECRYPT="${UTILSDIR}"/oppo_ozip_decrypt/ozipdecrypt.py
	OFP_QC_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_qc_decrypt.py
	OFP_MTK_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_mtk_decrypt.py
	OPSDECRYPT="${UTILSDIR}"/oppo_decrypt/opscrypto.py
	LPUNPACK="${UTILSDIR}"/lpunpack
	SPLITUAPP="${UTILSDIR}"/splituapp.py
	PACEXTRACTOR="${UTILSDIR}"/pacextractor/python/pacExtractor.py
	NB0_EXTRACT="${UTILSDIR}"/nb0-extract
	KDZ_EXTRACT="${UTILSDIR}"/kdztools/unkdz.py
	DZ_EXTRACT="${UTILSDIR}"/kdztools/undz.py
	RUUDECRYPT="${UTILSDIR}"/RUU_Decrypt_Tool
	EXTRACT_IKCONFIG="${UTILSDIR}"/extract-ikconfig
	UNPACKBOOT="${UTILSDIR}"/unpackboot.sh
	AML_EXTRACT="${UTILSDIR}"/aml-upgrade-package-extract
	AFPTOOL_EXTRACT="${UTILSDIR}"/bin/afptool
	RK_EXTRACT="${UTILSDIR}"/bin/rkImageMaker
	TRANSFER="${UTILSDIR}"/bin/transfer
	AVBTOOL="${UTILSDIR}"/avbtool.py

	if ! command -v 7zz > /dev/null 2>&1; then
		BIN_7ZZ="${UTILSDIR}"/bin/7zz
	else
		BIN_7ZZ=7zz
	fi

	if ! command -v uvx > /dev/null 2>&1; then
		export PATH="${HOME}/.local/bin:${PATH}"
	fi

	# Set Names of Downloader Utility Programs
	MEGAMEDIADRIVE_DL="${UTILSDIR}"/downloaders/mega-media-drive_dl.sh
	AFHDL="${UTILSDIR}"/downloaders/afh_dl.py

	# EROFS
	FSCK_EROFS=${UTILSDIR}/bin/fsck.erofs

	# Partition List That Are Currently Supported
	PARTITIONS="
	system system_ext systemex system_other system_dlkm
	vendor vendor_dlkm vendor_boot vendor_kernel_boot
	product product_h
	odm odm_dlkm odmko
	boot init_boot recovery dtbo dtb modem tz
	cust oem factory xrom hw_product mi_ext
	oppo_product opproduct preload preload_common special_preload
	my_preload my_odm my_stock my_operator my_country my_product my_company
	my_engineering my_heytap my_custom my_manifest my_carrier my_region
	my_bigball my_version
	tr_product tr_region tr_carrier tr_mi tr_preload tr_company
	tr_overlayfs tr_theme tr_manifest tr_misc
	preas preavs reserve version nt_log socko india
	"
	EXT4PARTITIONS="system vendor cust odm oem factory product xrom systemex oppo_product preload_common hw_product product_h preas preavs"
	OTHERPARTITIONS="tz.mbn:tz tz.img:tz modem.img:modem NON-HLOS:modem boot-verified.img:boot recovery-verified.img:recovery dtbo-verified.img:dtbo"

	# NOTE: $(pwd) is ${PROJECT_DIR}
	if [[ "${1}" == *"${PROJECT_DIR}/input"* ]] && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +10M -print | wc -l) -gt 1 ]]; then
		FILEPATH=$(printf "%s\n" "$1")		# Relative Path To Script
		FILEPATH=$(realpath "${FILEPATH}")	# Absolute Path
		printf "Copying Everything Into %s For Further Operations." "${WORK_TMPDIR}"
		cp -a "${FILEPATH}"/* "${WORK_TMPDIR}"/
		unset FILEPATH
	elif [[ "${1}" == *"${PROJECT_DIR}/input/"* ]] && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +300M -print | wc -l) -eq 1 ]]; then
		printf "Input Directory Exists And Contains File\n"
		cd "${INPUTDIR}"/ || exit
		# Input File Variables
		FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f -size +300M 2>/dev/null)	# INPUTDIR's FILEPATH is Always File
		FILE=${FILEPATH##*/}
		EXTENSION=${FILEPATH##*.}
		if [[ "${EXTENSION}" =~ ^(zip|rar|7z|tar)$ ]]; then
			UNZIP_DIR=${FILE%.*}			# Strip The File Extention With %.*
		fi
	else
		# Attempt To Download File/Folder From Internet
		if [[ "${1}" =~ ^(https?|ftp)://.+$ ]]; then
			URL=${1}
			mkdir -p "${INPUTDIR}" 2>/dev/null
			cd "${INPUTDIR}"/ || exit
			rm -rf "${INPUTDIR:?}"/* 2>/dev/null
			if [[ "${URL}" == *"mega.nz"* || "${URL}" == *"mediafire.com"* || "${URL}" == *"drive.google.com"* ]]; then
				( "${MEGAMEDIADRIVE_DL}" "${URL}" ) || exit 1
			elif [[ "${URL}" == *"androidfilehost.com"* ]]; then
				( python3 "${AFHDL}" -l "${URL}" ) || exit 1
			elif [[ "${URL}" == *"/we.tl/"* ]]; then
				( "${TRANSFER}" "${URL}" ) || exit 1
		else
				if [[ "${URL}" == *"1drv.ms"* ]]; then URL=${URL/ms/ws}; fi
				aria2c -x16 -s8 --console-log-level=warn --summary-interval=0 --check-certificate=false "${URL}" || {
					wget -q --show-progress --progress=bar:force --no-check-certificate "${URL}" || exit 1
				}
			fi
			unset URL
			for f in *; do detox -r "${f}" 2>/dev/null; done		# Detox Filename
			# Input File Variables
			FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)	# Single File
			printf "\nWorking with %s\n\n" "${FILEPATH##*/}"
			[[ $(echo "${FILEPATH}" | tr ' ' '\n' | wc -l) -gt 1 ]] && FILEPATH=$(find "$(pwd)" -maxdepth 2 -type d) 	# Base Folder
		else
			# For Local File/Folder, Do Not Use Input Directory
			FILEPATH=$(printf "%s\n" "$1")		# Relative Path To Script
			FILEPATH=$(realpath "${FILEPATH}")	# Absolute Path
			if [[ "${1}" == *" "* ]]; then
				if [[ -w "${FILEPATH}" ]]; then
					detox -r "${FILEPATH}" 2>/dev/null
					FILEPATH=$(echo "${FILEPATH}" | inline-detox)
				fi
			fi
			[[ ! -e "${FILEPATH}" ]] && { echo -e "Input File/Folder Doesn't Exist" && exit 1; }
		fi
		# Input File Variables
		FILE=${FILEPATH##*/}
		EXTENSION=${FILEPATH##*.}
		if [[ "${EXTENSION}" =~ ^(zip|rar|7z|tar)$ ]]; then
			UNZIP_DIR=${FILE%.*}			# Strip The File Extention With %.*
		fi
		if [[ -d "${FILEPATH}" || "${EXTENSION}" == "" ]]; then
			printf "Directory Detected.\n"
			if find "${FILEPATH}" -maxdepth 1 -type f | grep -v "compatibility.zip" | grep -q ".*.tar$\|.*.zip\|.*.rar\|.*.7z"; then
				printf "Supplied Folder Has Compressed Archive That Needs To Re-Load\n"
				# Set From Download Directory
				ArcPath=$(find "${INPUTDIR}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
				# If Empty, Set From Original Local Folder
				[[ -z "${ArcPath}" ]] && ArcPath=$(find "${FILEPATH}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
				if ! echo "${ArcPath}" | grep -q " "; then
					# Assuming There're Only One Archive To Re-Load And Process
					cd "${PROJECT_DIR}"/ || exit
					( bash "${0}" --mode "${MODE}" "${ArcPath}" ) || exit 1
					exit
				elif echo "${ArcPath}" | grep -q " "; then
					printf "More Than One Archive File Is Available In %s Folder.\nPlease Use Direct Archive Path Along With This Toolkit\n" "${FILEPATH}" && exit 1
				fi
			elif find "${FILEPATH}" -maxdepth 1 -type f | grep ".*system.ext4.tar.*\|.*chunk\|system\/build.prop\|system.new.dat\|system_new.img\|system.img\|system-sign.img\|system.bin\|payload.bin\|.*rawprogram*\|system.sin\|.*system_.*\.sin\|system-p\|super\|UPDATE.APP\|.*.pac\|.*.nb0" | grep -q -v ".*chunk.*\.so$"; then
				printf "Copying Everything Into %s For Further Operations." "${WORK_TMPDIR}"
				cp -a "${FILEPATH}"/* "${WORK_TMPDIR}"/
				unset FILEPATH
			else
				printf "\e[31m BRUH: This type of firmware is not supported.\e[0m\n"
				cd "${PROJECT_DIR}"/ || exit
				rm -rf "${WORK_TMPDIR}" "${OUTDIR}"
				exit 1
			fi
		fi
	fi

	cd "${PROJECT_DIR}"/ || exit

	# Function for Extracting Super Images
	function superimage_extract() {
		if [ -f super.img ]; then
			echo "Extracting Partitions from the Super Image..."
			${SIMG2IMG} super.img super.img.raw 2>/dev/null
		fi
		if [[ ! -s super.img.raw ]] && [ -f super.img ]; then
			mv super.img super.img.raw
		fi
		for partition in $PARTITIONS; do
			($LPUNPACK --partition="$partition"_a super.img.raw || $LPUNPACK --partition="$partition" super.img.raw) 2>/dev/null
			if [ -f "$partition"_a.img ]; then
				mv "$partition"_a.img "$partition".img
			else
				foundpartitions=$(echo "$ARCHIVE_LISTING" | rev | gawk '{ print $1 }' | rev | grep $partition.img)
				${BIN_7ZZ} e -y "${FILEPATH}" $foundpartitions dummypartition 2>/dev/null >> $WORK_TMPDIR/zip.log
			fi
		done
		rm -rf super.img.raw
	}

	# Cache archive listing once — avoids re-reading the archive on every check
	if [[ -f "${FILEPATH}" ]]; then
		ARCHIVE_LISTING=$(${BIN_7ZZ} l -ba "${FILEPATH}" 2>/dev/null)
	else
		ARCHIVE_LISTING=""
	fi

	printf "Extracting firmware on: %s\n" "${OUTDIR}"
	cd "${WORK_TMPDIR}"/ || exit

	# Oppo .ozip Check
	if [[ $(head -c12 "${FILEPATH}" 2>/dev/null | tr -d '\0') == "OPPOENCRYPT!" ]] || [[ "${EXTENSION}" == "ozip" ]]; then
		printf "Oppo/Realme ozip Detected.\n"
		stage_input_file
		printf "Decrypting ozip And Making A Zip...\n"
		python3 "${OZIPDECRYPT}" "${WORK_TMPDIR}"/"${FILE}"
		reset_inputdir
		if [[ -f "${FILE%.*}".zip ]]; then
			mv "${FILE%.*}".zip "${INPUTDIR}"/
		elif [[ -d "${WORK_TMPDIR}"/out ]]; then
			mv "${WORK_TMPDIR}"/out/* "${INPUTDIR}"/
		fi
		rm -rf "${WORK_TMPDIR:?}"/*
		printf "Re-Loading The Decrypted Content.\n"
		reload_and_rerun "${PROJECT_DIR}/input/" "${INPUTDIR}/${FILE%.*}.zip"
	fi
	# Oneplus .ops Check
	if echo "$ARCHIVE_LISTING" | grep -q ".*.ops" 2>/dev/null; then
		printf "Oppo/Oneplus ops Firmware Detected Extracting...\n"
		foundops=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep ".*.ops")
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundops}" */"${foundops}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
		mv "$(echo "${foundops}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/

		printf "Reloading the extracted OPS\n"
		cd "${PROJECT_DIR}"/ || exit
		( bash "${0}" --mode "${MODE}" "${PROJECT_DIR}/input/${foundops}" 2>/dev/null) || exit 1
		exit
	fi
	if [[ "${EXTENSION}" == "ops" ]]; then
		printf "Oppo/Oneplus ops Detected.\n"
		stage_input_file
		printf "Decrypting ops & extracing...\n"
		python3 "${OPSDECRYPT}" decrypt "${WORK_TMPDIR}"/"${FILE}"
		reset_inputdir
		mv "${WORK_TMPDIR}"/extract/* "${INPUTDIR}"/
		rm -rf "${WORK_TMPDIR:?}"/*
		printf "Re-Loading The Decrypted Content.\n"
		reload_and_rerun "${PROJECT_DIR}/input/" "${INPUTDIR}/${FILE%.*}.zip"
	fi
	# Oppo .ofp Check
	if echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep -q ".*.ofp" 2>/dev/null; then
		printf "Oppo ofp Detected.\n"
		foundofp=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep ".*.ofp")
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundofp}" */"${foundofp}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
		mv "$(echo "${foundofp}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/

		printf "Reloading the extracted OFP\n"
		cd "${PROJECT_DIR}"/ || exit
		( bash "${0}" --mode "${MODE}" "${PROJECT_DIR}/input/${foundofp}" 2>/dev/null) || exit 1
		exit
	fi
	if [[ "${EXTENSION}" == "ofp" ]]; then
		printf "Oppo ofp Detected.\n"
		stage_input_file
		printf "Decrypting ofp & extracing...\n"
		python3 "$OFP_QC_DECRYPT" "${WORK_TMPDIR}"/"${FILE}" out
		if [[ ! -f "${WORK_TMPDIR}"/out/boot.img || ! -f "${WORK_TMPDIR}"/out/userdata.img ]]; then
			python3 "$OFP_MTK_DECRYPT" "${WORK_TMPDIR}"/"${FILE}" out
			if [[ ! -f "${WORK_TMPDIR}"/out/boot.img || ! -f "${WORK_TMPDIR}"/out/userdata.img ]]; then
				printf "ofp decryption error.\n" && exit 1
			fi
		fi
		reset_inputdir
		if [[ -d "${WORK_TMPDIR}"/out ]]; then
			mv "${WORK_TMPDIR}"/out/* "${INPUTDIR}"/
		fi
		rm -rf "${WORK_TMPDIR:?}"/*
		printf "Re-Loading The Decrypted Contents.\n"
		reload_and_rerun "${PROJECT_DIR}/input/"
	fi
	# Xiaomi .tgz Check
	if [[ "${FILE##*.}" == "tgz" || "${FILE#*.}" == "tar.gz" ]]; then
		printf "Xiaomi gzipped tar archive found.\n"
		mkdir -p "${INPUTDIR}" 2>/dev/null
		if [[ -f "${INPUTDIR}"/"${FILE}" ]]; then
			tar xzvf "${INPUTDIR}"/"${FILE}" -C "${INPUTDIR}"/ --transform='s/.*\///'
			rm -rf -- "${INPUTDIR:?}"/"${FILE}"
		elif [[ -f "${FILEPATH}" ]]; then
			tar xzvf "${FILEPATH}" -C "${INPUTDIR}"/ --transform='s/.*\///'
		fi
		find "${INPUTDIR}"/ -type d -empty -delete     # Delete Empth Folder Leftover
		rm -rf "${WORK_TMPDIR:?}"/*
		printf "Re-Loading The Extracted Contents.\n"
		reload_and_rerun "${PROJECT_DIR}/input/"
	fi
	# LG KDZ Check
	if echo "${FILEPATH}" | grep -q ".*.kdz" || [[ "${EXTENSION}" == "kdz" ]]; then
		printf "LG KDZ Detected.\n"
		# Either Move Downloaded/Re-Loaded File Or Copy Local File
		mv -f "${INPUTDIR}"/"${FILE}" "${WORK_TMPDIR}"/ 2>/dev/null || cp -a "${FILEPATH}" "${WORK_TMPDIR}"/
		python3 "${KDZ_EXTRACT}" -f "${FILE}" -x -o "./" 2>/dev/null
		DZFILE=$(ls -- *.dz)
		printf "Extracting All Partitions As Individual Images.\n"
		python3 "${DZ_EXTRACT}" -f "${DZFILE}" -s -o "./" 2>/dev/null
		rm -f "${WORK_TMPDIR}"/"${FILE}" "${WORK_TMPDIR}"/"${DZFILE}" 2>/dev/null
		# dzpartitions="gpt_main persist misc metadata vendor system system_other product userdata gpt_backup tz boot dtbo vbmeta cust oem odm factory modem NON-HLOS"
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*.image" | while read -r i; do mv "${i}" "${i/.image/.img}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*_a.img" | while read -r i; do mv "${i}" "${i/_a.img/.img}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*_b.img" -exec rm -rf {} \;
	fi
	# HTC RUU Check
	if echo "${FILEPATH}" | grep -i "^ruu_" | grep -q -i "exe$" || [[ "${EXTENSION}" == "exe" ]]; then
		printf "HTC RUU Detected.\n"
		# Either Move Downloaded/Re-Loaded File Or Copy Local File
		mv -f "${INPUTDIR}"/"${FILE}" "${WORK_TMPDIR}"/ || cp -a "${FILEPATH}" "${WORK_TMPDIR}"/
		printf "Extracting System And Firmware Partitions...\n"
		"${RUUDECRYPT}" -s "${FILE}" 2>/dev/null
		"${RUUDECRYPT}" -f "${FILE}" 2>/dev/null
		find "${WORK_TMPDIR}"/OUT* -name "*.img" -exec mv {} "${WORK_TMPDIR}"/ \;
	fi

	# Amlogic upgrade package (AML) Check
	if [[ $(echo "$ARCHIVE_LISTING" | grep -i aml) ]]; then
		echo "AML Detected"
		cp "${FILEPATH}" "${WORK_TMPDIR}"
		FILE="${WORK_TMPDIR}/$(basename "${FILEPATH}")"
		${BIN_7ZZ} e -y "${FILEPATH}" >> "${WORK_TMPDIR}"/zip.log
		"${AML_EXTRACT}" $(find . -type f -name "*aml*.img")
		rename 's/.PARTITION$/.img/' *.PARTITION
		rename 's/_aml_dtb.img$/dtb.img/' *.img
		rename 's/_a.img/.img/' *.img
		if [[ -f super.img ]]; then
			superimage_extract || exit 1
		fi
		for partition in $PARTITIONS; do
			[[ -e "${WORK_TMPDIR}/${partition}.img" ]] && mv "${WORK_TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
		done
		rm -rf "${WORK_TMPDIR:?}"
	fi

	# Extract & Move Raw Otherpartitons To OUTDIR
	if [[ -f "${FILEPATH}" ]]; then
		for otherpartition in ${OTHERPARTITIONS}; do
			filename=${otherpartition%:*} && outname=${otherpartition#*:}
			if echo "$ARCHIVE_LISTING" | grep -q "${filename}"; then
				printf "%s Detected For %s\n" "${filename}" "${outname}"
				foundfile=$(echo "$ARCHIVE_LISTING" | grep "${filename}" | awk '{print $NF}')
				${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundfile}" */"${foundfile}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
				output=$(ls -- "${filename}"* 2>/dev/null)
				[[ ! -e "${WORK_TMPDIR}"/"${outname}".img ]] && mv "${output}" "${WORK_TMPDIR}"/"${outname}".img
				"${SIMG2IMG}" "${WORK_TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
				[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${WORK_TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
			fi
		done
	fi

	# Extract/Put Image/Extra Files In WORK_TMPDIR
	if echo "$ARCHIVE_LISTING" | grep -q "system.new.dat" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system.new.dat*" -print | wc -l) -ge 1 ]]; then
		printf "A-only DAT-Formatted OTA detected.\n"
		for partition in $PARTITIONS; do
			${BIN_7ZZ} e -y "${FILEPATH}" ${partition}.new.dat* ${partition}.transfer.list ${partition}.img 2>/dev/null >> ${WORK_TMPDIR}/zip.log
			${BIN_7ZZ} e -y "${FILEPATH}" ${partition}.*.new.dat* ${partition}.*.transfer.list ${partition}.*.img 2>/dev/null >> ${WORK_TMPDIR}/zip.log
			rename 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
			# For Oplus A-only OTAs, eg OnePlus Nord 2. Regex matches the 8 digits of Oplus NV ID (prop ro.build.oplus_nv_id) to remove them.
			# hello@world:~/test_regex# rename -n 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
			# rename(my_bigball.00011011.new.dat.br, my_bigball.new.dat.br)
			# rename(my_bigball.00011011.patch.dat, my_bigball.patch.dat)
			# rename(my_bigball.00011011.transfer.list, my_bigball.transfer.list)
			if [[ -f ${partition}.new.dat.1 ]]; then
				cat ${partition}.new.dat.{0..999} 2>/dev/null >> ${partition}.new.dat
				rm -rf ${partition}.new.dat.{0..999}
			fi
			ls | grep "\.new\.dat" | while read i; do
				line=$(echo "$i" | cut -d"." -f1)
				if [[ $(echo "$i" | grep "\.dat\.xz") ]]; then
					${BIN_7ZZ} e -y "$i" 2>/dev/null >> ${WORK_TMPDIR}/zip.log
					rm -rf "$i"
				fi
				if [[ $(echo "$i" | grep "\.dat\.br") ]]; then
					echo "Converting brotli ${partition} dat to normal"
					brotli -d "$i"
					rm -f "$i"
				fi
				echo "Extracting ${partition}"
				python3 ${SDAT2IMG} ${line}.transfer.list ${line}.new.dat "${OUTDIR}"/${line}.img > ${WORK_TMPDIR}/extract.log
				rm -rf ${line}.transfer.list ${line}.new.dat
			done
		done
	elif echo "$ARCHIVE_LISTING" | grep rawprogram || [[ $(find "${WORK_TMPDIR}" -type f -name "*rawprogram*" | wc -l) -ge 1 ]]; then
		echo "QFIL Detected"
		rawprograms=$(echo "$ARCHIVE_LISTING" | gawk '{ print $NF }' | grep rawprogram)
		${BIN_7ZZ} e -y ${FILEPATH} $rawprograms 2>/dev/null >> ${WORK_TMPDIR}/zip.log
		for partition in $PARTITIONS; do
			partitionsonzip=$(echo "$ARCHIVE_LISTING" | gawk '{ print $NF }' | grep $partition)
			if [[ ! $partitionsonzip == "" ]]; then
				${BIN_7ZZ} e -y ${FILEPATH} $partitionsonzip 2>/dev/null >> ${WORK_TMPDIR}/zip.log
				if [[ ! -f "$partition.img" ]]; then
					if [[ -f "$partition.raw.img" ]]; then
						mv "$partition.raw.img" "$partition.img"
					else
						rawprogramsfile=rawprogram_unsparse0.xml
						"${PACKSPARSEIMG}" -t $partition -x $rawprogramsfile > ${WORK_TMPDIR}/extract.log
						mv "$partition.raw" "$partition.img"
					fi
				fi
			fi
		done
		if [[ -f super.img ]]; then
			superimage_extract || exit 1
		fi
	elif echo "$ARCHIVE_LISTING" | grep -q ".*.nb0" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "*.nb0*" | wc -l) -ge 1 ]]; then
		printf "nb0-Formatted Firmware Detected.\n"
		if [[ -f "${FILEPATH}" ]]; then
			to_extract=$(echo "$ARCHIVE_LISTING" | grep ".*.nb0" | gawk '{print $NF}')
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${to_extract}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		else
			find "${WORK_TMPDIR}" -type f -name "*.nb0*" -exec mv {} . \; 2>/dev/null
		fi
		"${NB0_EXTRACT}" "${to_extract}" "${WORK_TMPDIR}"
	elif echo "$ARCHIVE_LISTING" | grep system | grep chunk | grep -q -v ".*\.so$" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "*system*chunk*" | wc -l) -ge 1 ]]; then
		printf "Chunk Detected.\n"
		for partition in ${PARTITIONS}; do
			if [[ -f "${FILEPATH}" ]]; then
				foundpartitions=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep ${partition}.img)
				${BIN_7ZZ} e -y -- "${FILEPATH}" *${partition}*chunk* */*${partition}*chunk* "${foundpartitions}" dummypartition 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
			else
				find "${WORK_TMPDIR}" -type f -name "*${partition}*chunk*" -exec mv {} . \; 2>/dev/null
				find "${WORK_TMPDIR}" -type f -name "*${partition}*.img" -exec mv {} . \; 2>/dev/null
			fi
			rm -f -- *"${partition}"_b*
			rm -f -- *"${partition}"_other*
			romchunk=$(find . -maxdepth 1 -type f -name "*${partition}*chunk*" | cut -d'/' -f'2-' | sort)
			if echo "${romchunk}" | grep -q "sparsechunk"; then
				if [[ ! -f "${partition}".img ]]; then
					"${SIMG2IMG}" *${partition}*chunk* "${partition}".img.raw 2>/dev/null
					mv ${partition}.img.raw ${partition}.img
				fi
				rm -rf -- *${partition}*chunk* 2>/dev/null
			fi
		done
	elif echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep -q "system_new.img\|^system.img\|\/system.img\|\/system_image.emmc.img\|^system_image.emmc.img" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system*.img" | wc -l) -ge 1 ]]; then
		printf "Image File detected.\n"
		if [[ -f "${FILEPATH}" ]]; then
			${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		fi
		for f in "${WORK_TMPDIR}"/*; do detox -r "${f}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*_image.emmc.img" | while read -r i; do mv "${i}" "${i/_image.emmc.img/.img}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*_new.img" | while read -r i; do mv "${i}" "${i/_new.img/.img}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*.img.ext4" | while read -r i; do mv "${i}" "${i/.img.ext4/.img}" 2>/dev/null; done
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*.img" -exec mv {} . \;	# move .img in sub-dir to ${WORK_TMPDIR}
		### Keep some files, add script here to retain them
		find "${WORK_TMPDIR}" -type f -iname "*Android_scatter.txt" -exec mv {} "${OUTDIR}"/ \;
		find "${WORK_TMPDIR}" -type f -iname "*Android_scatter.xml" -exec mv {} "${OUTDIR}"/ \;
		find "${WORK_TMPDIR}" -type f -iname "DA_BR.bin" -exec sh -c '
			mkdir -p "${0}/download_agent"
			mv "$1" "${0}/download_agent/"
			' "${OUTDIR}" {} \;
		find "${WORK_TMPDIR}" -type f -iname "*Release_Note.txt" -exec mv {} "${OUTDIR}"/ \;
		find "${WORK_TMPDIR}" -type f ! -name "*img*" -exec rm -rf {} \;	# delete other files
		find "${WORK_TMPDIR}" -maxdepth 3 -type f -name "*.img" -exec mv {} . \; 2>/dev/null
	elif echo "$ARCHIVE_LISTING" | grep -q "system.sin\|.*system_.*\.sin" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system*.sin" | wc -l) -ge 1 ]]; then
		printf "sin Image Detected.\n"
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		# Remove Unnecessary Filename Part
		to_remove=$(find . -type f | grep ".*boot_.*\.sin" | gawk '{print $NF}' | sed -e 's/boot_\(.*\).sin/\1/')
		[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*cache_.*\.sin" | gawk '{print $NF}' | sed -e 's/cache_\(.*\).sin/\1/')
		[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*vendor_.*\.sin" | gawk '{print $NF}' | sed -e 's/vendor_\(.*\).sin/\1/')
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*.sin" -exec mv {} . \;	# move .img in sub-dir to ${WORK_TMPDIR}
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*_${to_remove}.sin" | while read -r i; do mv "${i}" "${i/_${to_remove}.sin/.sin}" 2>/dev/null; done	# proper names
		"${UNSIN}" -d "${WORK_TMPDIR}"
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*.ext4" | while read -r i; do mv "${i}" "${i/.ext4/.img}" 2>/dev/null; done	# proper names
		foundsuperinsin=$(find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "super_*.img")
		if [[ -n "$foundsuperinsin" ]]; then
			mv "${WORK_TMPDIR}"/super_*.img "${WORK_TMPDIR}/super.img"
			echo "super image inside a sin detected"
			superimage_extract || exit 1
		fi
	elif echo "$ARCHIVE_LISTING" | grep ".pac$" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "*.pac" | wc -l) -ge 1 ]]; then
		printf "pac Detected.\n"
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		for f in "${WORK_TMPDIR}"/*; do detox -r "${f}"; done
		pac_list=$(find . -type f -name "*.pac" | cut -d'/' -f'2-' | sort)
		for file in ${pac_list}; do
			python3 "${PACEXTRACTOR}" "${file}" $(pwd)
		done
		if [[ -f super.img ]]; then
			superimage_extract || exit 1
		fi
	elif echo "$ARCHIVE_LISTING" | grep -q "system.bin" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system.bin" | wc -l) -ge 1 ]]; then
		printf "bin Images Detected\n"
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*.bin" -exec mv {} . \;	# move .img in sub-dir to ${WORK_TMPDIR}
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*.bin" | while read -r i; do mv "${i}" "${i/\.bin/.img}" 2>/dev/null; done	# proper names
	elif echo "$ARCHIVE_LISTING" | grep -q "system-p" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system-p*" | wc -l) -ge 1 ]]; then
		printf "P-Suffix Images Detected\n"
		for partition in ${PARTITIONS}; do
			if [[ -f "${FILEPATH}" ]]; then
				foundpartitions=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep "${partition}-p")
				${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpartitions}" dummypartition 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
			else
				foundpartitions=$(find . -type f -name "*${partition}-p*" | cut -d'/' -f'2-')
			fi
		[[ -n "${foundpartitions}" ]] && mv "$(ls "${partition}"-p*)" "${partition}".img
		done
	elif echo "$ARCHIVE_LISTING" | grep -q "system-sign.img" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "system-sign.img" | wc -l) -ge 1 ]]; then
		printf "Signed Images Detected\n"
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		for f in "${WORK_TMPDIR}"/*; do detox -r "${f}"; done
		for partition in ${PARTITIONS}; do
			[[ -e "${WORK_TMPDIR}"/"${partition}".img ]] && mv "${WORK_TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
		done
		find "${WORK_TMPDIR}" -mindepth 2 -type f -name "*-sign.img" -exec mv {} . \;	# move .img in sub-dir to ${WORK_TMPDIR}
		find "${WORK_TMPDIR}" -type f ! -name "*-sign.img" -exec rm -rf {} \;	# delete other files
		find "${WORK_TMPDIR}" -maxdepth 1 -type f -name "*-sign.img" | while read -r i; do mv "${i}" "${i/-sign.img/.img}" 2>/dev/null; done	# proper .img names
		sign_list=$(find . -maxdepth 1 -type f -name "*.img" | cut -d'/' -f'2-' | sort)
		for file in ${sign_list}; do
			rm -rf "${WORK_TMPDIR}"/x.img >/dev/null 2>&1
			MAGIC=$(head -c4 "${WORK_TMPDIR}"/"${file}" | tr -d '\0')
			if [[ "${MAGIC}" == "SSSS" ]]; then
				printf "Cleaning %s with SSSS header\n" "${file}"
				# This Is For little_endian Arch
				offset_low=$(od -A n -x -j 60 -N 2 "${WORK_TMPDIR}"/"${file}" | sed 's/ //g')
				offset_high=$(od -A n -x -j 62 -N 2 "${WORK_TMPDIR}"/"${file}" | sed 's/ //g')
				offset_low=0x${offset_low:0-4}
				offset_high=0x${offset_high:0-4}
				offset_low=$(printf "%d" "${offset_low}")
				offset_high=$(printf "%d" "${offset_high}")
				offset=$((65536*offset_high+offset_low))
				dd if="${WORK_TMPDIR}"/"${file}" of="${WORK_TMPDIR}"/x.img iflag=count_bytes,skip_bytes bs=8192 skip=64 count=${offset} >/dev/null 2>&1
			else	# Header With BFBF Magic Or Another Unknowed Header
				dd if="${WORK_TMPDIR}"/"${file}" of="${WORK_TMPDIR}"/x.img bs=$((0x4040)) skip=1 >/dev/null 2>&1
			fi
		done
	elif [[ $(echo "$ARCHIVE_LISTING" | grep "super.img") ]]; then
		echo "Super Image detected"
		foundsupers=$(echo "$ARCHIVE_LISTING" | gawk '{ print $NF }' | grep "super.img")
		${BIN_7ZZ} e -y "${FILEPATH}" $foundsupers dummypartition 2>/dev/null >> ${WORK_TMPDIR}/zip.log
		superchunk=$(ls | grep chunk | grep super | sort)
		if [[ $(echo "$superchunk" | grep "sparsechunk") ]]; then
			"${SIMG2IMG}" $(echo "$superchunk" | tr '\n' ' ') super.img.raw 2>/dev/null
			rm -rf *super*chunk*
		fi
		superimage_extract || exit 1
	elif [[ $(find "${WORK_TMPDIR}" -type f -name "super*.*img" | wc -l) -ge 1 ]]; then
		echo "Super Image Detected"
		if [[ -f "${FILEPATH}" ]]; then
			foundsupers=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep "super.*img")
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundsupers}" dummypartition 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		fi
		splitsupers=$(ls | grep -oP "super.[0-9].+.img")
		if [[ ! -z "${splitsupers}" ]]; then
			printf "Creating super.img.raw ...\n"
			"${SIMG2IMG}" ${splitsupers} super.img.raw 2>/dev/null
			rm -rf -- ${splitsupers}
		fi
		superchunk=$(find . -maxdepth 1 -type f -name "*super*chunk*" | cut -d'/' -f'2-' | sort)
		if echo "${superchunk}" | grep -q "sparsechunk"; then
			printf "Creating super.img.raw ...\n"
			"${SIMG2IMG}" ${superchunk} super.img.raw 2>/dev/null
			rm -rf -- *super*chunk*
		fi
		superimage_extract || exit 1
	elif echo "$ARCHIVE_LISTING" | grep tar.md5 | gawk '{print $NF}' | grep -q AP_ 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "*AP_*tar.md5" | wc -l) -ge 1 ]]; then
		printf "AP tarmd5 Detected\n"
		#mv -f "${FILEPATH}" "${WORK_TMPDIR}"/
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} e -y "${FILEPATH}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		printf "Extracting Images...\n"
		for i in *.tar.md5; do
			[[ -f "${i}" ]] || continue
			tar -xf "${i}" || exit 1
			rm -fv "${i}" || exit 1
			printf "Extracted %s\n" "${i}"
		done
		[[ $(ls *.lz4 2>/dev/null) ]] && {
			printf "Extracting lz4 Archives...\n"
			for f in *.lz4; do
				[[ -f "${f}" ]] || continue
				lz4 -dc "${f}" > "${f/.lz4/}" || exit 1
				rm -fv "${f}" || exit 1
				printf "Extracted %s\n" "${f}"
			done
		}
		for samsung_ext4_img_files in $(find -maxdepth 1 -type f -name \*.ext4 -printf '%P\n'); do
			mv -v "$samsung_ext4_img_files" "${samsung_ext4_img_files%%.ext4}"
		done
		if [[ -f super.img ]]; then
			superimage_extract || exit 1
		fi
		if [[ ! -f system.img ]]; then
			printf "Extract failed\n"
			rm -rf "${WORK_TMPDIR}" && exit 1
		fi
	elif echo "$ARCHIVE_LISTING" | grep -q payload.bin 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "payload.bin" | wc -l) -ge 1 ]]; then
		printf "AB OTA Payload Detected\n"
		${PAYLOAD_EXTRACTOR} -c "$(nproc --all)" -o "${WORK_TMPDIR}" "${FILEPATH}" >/dev/null
	elif echo "$ARCHIVE_LISTING" | grep ".*.rar\|.*.zip\|.*.7z\|.*.tar$" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | wc -l) -ge 1 ]]; then
		printf "Rar/Zip/7Zip/Tar Archived Firmware Detected\n"
		if [[ -f "${FILEPATH}" ]]; then
			mkdir -p "${WORK_TMPDIR}"/"${UNZIP_DIR}" 2>/dev/null
			${BIN_7ZZ} e -y "${FILEPATH}" -o"${WORK_TMPDIR}"/"${UNZIP_DIR}"  >> "${WORK_TMPDIR}"/zip.log
			for f in "${WORK_TMPDIR}"/"${UNZIP_DIR}"/*; do detox -r "${f}" 2>/dev/null; done
		fi
		zip_list=$(find ./"${UNZIP_DIR}" -type f -size +300M \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | cut -d'/' -f'2-' | sort)
		mkdir -p "${INPUTDIR}" 2>/dev/null
		rm -rf "${INPUTDIR:?}"/* 2>/dev/null
		for file in ${zip_list}; do
			mv "${WORK_TMPDIR}"/"${file}" "${INPUTDIR}"/
			rm -rf "${WORK_TMPDIR:?}"/*
			cd "${PROJECT_DIR}"/ || exit
			( bash "${0}" --mode "${MODE}" "${INPUTDIR}"/"${file}" ) || exit 1
			exit
		done
		rm -rf "${WORK_TMPDIR:?}"/"${UNZIP_DIR}"
	elif echo "$ARCHIVE_LISTING" | grep -q "UPDATE.APP" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "UPDATE.APP") ]]; then
		printf "Huawei UPDATE.APP Detected\n"
		[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x "${FILEPATH}" UPDATE.APP 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		find "${WORK_TMPDIR}" -type f -name "UPDATE.APP" -exec mv {} . \;
		python3 "${SPLITUAPP}" -f "UPDATE.APP" -l || (
		for partition in ${PARTITIONS}; do
			python3 "${SPLITUAPP}" -f "UPDATE.APP" -l "${partition/.img/}" || printf "%s not found in UPDATE.APP\n" "${partition}"
		done )
		find output/ -type f -name "*.img" -exec mv {} . \;	# Partitions Are Extracted In "output" Folder
		"${SIMG2IMG}" super*.img super.img.raw 2>/dev/null && rm super*.img
		if [[ -f super.img ]]; then
			printf "Creating super.img.raw ...\n"
			"${SIMG2IMG}" super.img super_* super.img.raw 2>/dev/null
			[[ ! -s super.img.raw && -f super.img ]] && mv super.img super.img.raw
		fi
		superimage_extract || exit 1
	elif echo "$ARCHIVE_LISTING" | grep -q "rockchip" 2>/dev/null || [[ $(find "${WORK_TMPDIR}" -type f -name "rockchip") ]]; then
		printf "Rockchip Detected\n"
		${RK_EXTRACT} -unpack "${FILEPATH}" ${WORK_TMPDIR}
		${AFPTOOL_EXTRACT} -unpack ${WORK_TMPDIR}/firmware.img ${WORK_TMPDIR}
		[ -f ${WORK_TMPDIR}/Image/super.img ] && {
			mv ${WORK_TMPDIR}/Image/super.img ${WORK_TMPDIR}/super.img
			cd ${WORK_TMPDIR}
			superimage_extract || exit 1
			cd -
		}
		for partition in $PARTITIONS; do
			[[ -e "${WORK_TMPDIR}/Image/${partition}.img" ]] && mv "${WORK_TMPDIR}/Image/${partition}.img" "${OUTDIR}/${partition}.img"
			[[ -e "${WORK_TMPDIR}/${partition}.img" ]] && mv "${WORK_TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
		done
	fi

	# PAC Archive Check
	if [[ "${EXTENSION}" == "pac" ]]; then
		printf "PAC Archive Detected.\n"
		python3 ${PACEXTRACTOR} ${FILEPATH} $(pwd)
		superimage_extract || exit 1
		exit
	fi

	# $(pwd) == "${WORK_TMPDIR}"

	# Process All otherpartitions From WORK_TMPDIR Now
	for otherpartition in ${OTHERPARTITIONS}; do
		filename=${otherpartition%:*} && outname=${otherpartition#*:}
		output=$(ls -- "${filename}"* 2>/dev/null)
		if [[ -f "${output}" ]]; then
			printf "%s Detected For %s\n" "${output}" "${outname}"
			[[ ! -e "${WORK_TMPDIR}"/"${outname}".img ]] && mv "${output}" "${WORK_TMPDIR}"/"${outname}".img
			"${SIMG2IMG}" "${WORK_TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
			[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${WORK_TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
		fi
	done

	# Process All partitions From WORK_TMPDIR Now
	for partition in ${PARTITIONS}; do
		if [[ ! -f "${partition}".img ]]; then
			foundpart=$(echo "$ARCHIVE_LISTING" | gawk '{print $NF}' | grep "${partition}.img" 2>/dev/null)
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpart}" */"${foundpart}" 2>/dev/null >> "${WORK_TMPDIR}"/zip.log
		fi
		[[ -f "${partition}".img ]] && "${SIMG2IMG}" "${partition}".img "${OUTDIR}"/"${partition}".img 2>/dev/null
		[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${WORK_TMPDIR}"/"${partition}".img ]] && mv "${WORK_TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
		if [[ "${EXT4PARTITIONS}" =~ (^|[[:space:]])"${partition}"($|[[:space:]]) && -f "${OUTDIR}"/"${partition}".img ]]; then
			MAGIC=$(head -c12 "${OUTDIR}"/"${partition}".img | tr -d '\0')
			offset=$(LANG=C grep -aobP -m1 '\x53\xEF' "${OUTDIR}"/"${partition}".img | head -1 | gawk '{print $1 - 1080}')
			if [[ "${MAGIC}" == *"MOTO"* ]]; then
				[[ "$offset" == 128055 ]] && offset=131072
				printf "MOTO header detected on %s in %s\n" "${partition}" "${offset}"
			elif [[ "${MAGIC}" == *"ASUS"* ]]; then
				printf "ASUS header detected on %s in %s\n" "${partition}" "${offset}"
			else
				offset=0
			fi
			if [[ ! "${offset}" == "0" ]]; then
				dd if="${OUTDIR}"/"${partition}".img of="${OUTDIR}"/"${partition}".img-2 ibs=$offset skip=1 2>/dev/null
				mv -f "${OUTDIR}"/"${partition}".img-2 "${OUTDIR}"/"${partition}".img
			fi
		fi
		[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${OUTDIR}"/"${partition}".img ]] && rm "${OUTDIR}"/"${partition}".img
	done

	# Preserve super_*.img chunks in OUTDIR before extraction cleanup
	if compgen -G "super_*.img" > /dev/null; then
		mv super_*.img "${OUTDIR}"/
	fi

	cd "${OUTDIR}"/ || exit
	rm -rf "${WORK_TMPDIR:?}"/*

	# Extract boot.img
	if [[ -f "${OUTDIR}"/boot.img ]]; then
		# Extract dts
		mkdir -p "${OUTDIR}"/bootimg "${OUTDIR}"/bootdts 2>/dev/null
		uvx -q extract-dtb "${OUTDIR}"/boot.img -o "${OUTDIR}"/bootimg >/dev/null
		find "${OUTDIR}"/bootimg -name '*.dtb' -type f | gawk -F'/' '{print $NF}' | while read -r i; do "${DTC}" -q -s -f -I dtb -O dts -o bootdts/"${i/\.dtb/.dts}" bootimg/"${i}"; done 2>/dev/null
		bash "${UNPACKBOOT}" "${OUTDIR}"/boot.img "${OUTDIR}"/boot 2>/dev/null
		python3 "${AVBTOOL}" info_image --image "${OUTDIR}"/boot.img > "${OUTDIR}"/boot/avb.txt 2>/dev/null
		printf "Boot extracted\n"
		# extract-ikconfig
		mkdir -p "${OUTDIR}"/bootRE
		bash "${EXTRACT_IKCONFIG}" "${OUTDIR}"/boot.img > "${OUTDIR}"/bootRE/ikconfig 2> /dev/null
		[[ ! -s "${OUTDIR}"/bootRE/ikconfig ]] && rm -f "${OUTDIR}"/bootRE/ikconfig 2>/dev/null
		# vmlinux-to-elf
		if [[ ! -f "${OUTDIR}"/vendor_boot.img ]]; then
			python3 "${KALLSYMS_FINDER}" "${OUTDIR}"/boot.img > "${OUTDIR}"/bootRE/boot_kallsyms.txt >/dev/null 2>&1
			printf "boot_kallsyms.txt generated\n"
		else
			python3 "${KALLSYMS_FINDER}" "${OUTDIR}"/boot/kernel > "${OUTDIR}"/bootRE/kernel_kallsyms.txt >/dev/null 2>&1
			printf "kernel_kallsyms.txt generated\n"
		fi
		python3 "${VMLINUX2ELF}" "${OUTDIR}"/boot.img "${OUTDIR}"/bootRE/boot.elf >/dev/null 2>&1
		printf "boot.elf generated\n"
		[[ -f "${OUTDIR}"/boot/dtb.img ]] && {
			mkdir -p "${OUTDIR}"/dtbimg 2>/dev/null
			uvx -q extract-dtb "${OUTDIR}"/boot/dtb.img -o "${OUTDIR}"/dtbimg >/dev/null
		}
	fi

	# Extract vendor_boot.img
	if [[ -f "${OUTDIR}"/vendor_boot.img ]]; then
		# Extract dts
		mkdir -p "${OUTDIR}"/vendor_bootimg "${OUTDIR}"/vendor_bootdts 2>/dev/null
		uvx -q extract-dtb "${OUTDIR}"/vendor_boot.img -o "${OUTDIR}"/vendor_bootimg >/dev/null
		find "${OUTDIR}"/vendor_bootimg -name '*.dtb' -type f | gawk -F'/' '{print $NF}' | while read -r i; do "${DTC}" -q -s -f -I dtb -O dts -o vendor_bootdts/"${i/\.dtb/.dts}" vendor_bootimg/"${i}"; done 2>/dev/null
		bash "${UNPACKBOOT}" "${OUTDIR}"/vendor_boot.img "${OUTDIR}"/vendor_boot 2>/dev/null
		printf "Vendor Boot extracted\n"
		# extract-ikconfig
		mkdir -p "${OUTDIR}"/vendor_bootRE
		# vmlinux-to-elf
		python3 "${VMLINUX2ELF}" "${OUTDIR}"/vendor_boot.img "${OUTDIR}"/vendor_bootRE/vendor_boot.elf >/dev/null 2>&1
		printf "vendor_boot.elf generated\n"
		[[ -f "${OUTDIR}"/vendor_boot/dtb.img ]] && {
			mkdir -p "${OUTDIR}"/vendor_dtbimg 2>/dev/null
			uvx -q extract-dtb "${OUTDIR}"/vendor_boot/dtb.img -o "${OUTDIR}"/vendor_dtbimg >/dev/null
		}
	fi

	# Extract init_boot.img
	if [[ -f "${OUTDIR}"/init_boot.img ]]; then
		bash "${UNPACKBOOT}" "${OUTDIR}"/init_boot.img "${OUTDIR}"/init_boot 2>/dev/null
		printf "Init Boot extracted\n"
	fi

	# Extract recovery.img
	if [[ -f "${OUTDIR}"/recovery.img ]]; then
		bash "${UNPACKBOOT}" "${OUTDIR}"/recovery.img "${OUTDIR}"/recovery 2>/dev/null
		printf "Recovery extracted\n"
	fi

	# Extract dtbo
	if [[ -f "${OUTDIR}"/dtbo.img ]]; then
		mkdir -p "${OUTDIR}"/dtbo "${OUTDIR}"/dtbodts 2>/dev/null
		uvx -q extract-dtb "${OUTDIR}"/dtbo.img -o "${OUTDIR}"/dtbo >/dev/null
		find "${OUTDIR}"/dtbo -name '*.dtb' -type f | gawk -F'/' '{print $NF}' | while read -r i; do "${DTC}" -q -s -f -I dtb -O dts -o dtbodts/"${i/\.dtb/.dts}" dtbo/"${i}"; done 2>/dev/null
		printf "dtbo extracted\n"
	fi

	# Extract Partitions
	for p in $PARTITIONS; do
		if ! [[ "${p}" =~ ^(boot|init_boot|recovery|dtbo|vendor_boot|tz|vbmeta)$ ]]; then
			if [[ -e "$p.img" ]]; then
				mkdir "$p" 2> /dev/null || rm -rf "${p:?}"/*
				echo "Trying to extract $p partition via fsck.erofs."
				"${FSCK_EROFS}" --extract="$p" "$p".img
				if [ $? -eq 0 ]; then
					rm "$p".img > /dev/null 2>&1
				else
					if [[ -f "$p.img" ]] && [[ "$p" != "modem" ]]; then
						echo "Extraction via fsck.erofs failed, extracting $p partition via 7zz"
						rm -rf "${p}"/*
						${BIN_7ZZ} x -snld "$p".img -y -o"$p"/ > /dev/null 2>&1
						if [ $? -eq 0 ]; then
							rm -fv "$p".img > /dev/null 2>&1
						else
							echo "Extraction via 7zz failed!"
							echo "Couldn't extract $p partition via 7zz. Using mount loop"
							sudo mount -o loop -t auto "$p".img "$p"
							mkdir "${p}_"
							sudo cp -rf "${p}/"* "${p}_"
							sudo umount "${p}"
							sudo cp -rf "${p}_/"* "${p}"
							sudo rm -rf "${p}_"
							sudo chown -R "$(whoami)" "${p}"/*
							chmod -R u+rwX "${p}"/*
							if [ $? -eq 0 ]; then
								rm -fv "$p".img > /dev/null 2>&1
							else
								echo "Couldn't extract $p partition. It might use an unsupported filesystem."
								echo "For EROFS: make sure you're using Linux 5.4+ kernel."
								echo "For F2FS: make sure you're using Linux 5.15+ kernel."
							fi
						fi
					fi
				fi
			fi
		fi
	done

	# Identify partitions extracted from super_*.img chunks
	if compgen -G "super_*.img" > /dev/null; then
		BASE_TARGET="."
		echo "Extracting and identifying partitions..."

		for i in {2..17}; do
			FILE="super_${i}.img"
			[[ -f "${FILE}" ]] || continue
			"${FSCK_EROFS}" "${FILE}" &>/dev/null || continue

			TEMP_DIR="temp_chunk_${i}"
			rm -rf "${TEMP_DIR}"
			mkdir -p "${TEMP_DIR}"

			if ! "${FSCK_EROFS}" --extract="${TEMP_DIR}" "${FILE}" &>/dev/null; then
				rm -rf "${TEMP_DIR}"
				continue
			fi

			PART_NAME=""

			# vendor_dlkm detection
			if find "${TEMP_DIR}" -type d -path "*/lib/modules/*android*" -print -quit | grep -q .; then
				PART_NAME="system_dlkm"

			# tr_manifest detection
			elif [ "$(find "${TEMP_DIR}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ] \
				&& [ -f "${TEMP_DIR}/build.prop" ]; then
				PART_NAME="tr_manifest"
			else
				PROP_FILE=""

				if [ -f "${TEMP_DIR}/build.prop" ]; then
					PROP_FILE="${TEMP_DIR}/build.prop"
				elif [ -f "${TEMP_DIR}/etc/build.prop" ]; then
					PROP_FILE="${TEMP_DIR}/etc/build.prop"
				elif [ -f "${TEMP_DIR}/system/build.prop" ]; then
					PROP_FILE="${TEMP_DIR}/system/build.prop"
				fi

				if [ -n "${PROP_FILE}" ]; then
					PART_NAME=$(grep -oP 'ro\.product\.\K[^.]+' "${PROP_FILE}" | head -n 1)
				fi
			fi

			# Fallback if still empty
			[ -n "${PART_NAME}" ] || PART_NAME="unknown"

			# Handle duplicates
			FINAL_PATH="${BASE_TARGET}/${PART_NAME}"
			COUNTER=2
			while [ -d "${FINAL_PATH}" ]; do
				FINAL_PATH="${BASE_TARGET}/${PART_NAME}_${COUNTER}"
				((COUNTER++))
			done

			echo "Chunk ${i} identified as [${PART_NAME}] -> ${FINAL_PATH}"
			mv "${TEMP_DIR}" "${FINAL_PATH}"
		done

		echo "Done. Check '${BASE_TARGET}'."
	fi

	# Remove Unnecessary Image Leftover From OUTDIR
	for q in *.img; do
		if ! [[ "${q}" =~ (boot|recovery|dtbo|tz|vbmeta) ]]; then
			rm -f "${q}" 2>/dev/null
		fi
	done
else
	if [[ ! -d "${OUTDIR}" ]]; then
		printf "\n  \e[1;31;40m \u2620 Error: Output Directory %s Not Found.\e[0m\n\n" "${OUTDIR}"
		exit 1
	fi
	cd "${OUTDIR}"/ || exit
fi

rm -rf "${OUTDIR}"/.git

# Oppo/Realme Devices Have Some Images In A Euclid Folder In Their Vendor and/or System, Extract Those For Props
for dir in "vendor/euclid" "system/system/euclid"; do
	if [[ -d "${dir}" ]]; then
		pushd "${dir}" || exit 1
		for f in *.img; do
			[[ -f "${f}" ]] || continue
			${BIN_7ZZ} x "${f}" -o"${f/.img/}"
			rm -f "${f}"
		done
		popd || exit 1
	fi
done

# board-info.txt
find "${OUTDIR}"/modem -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> "${WORK_TMPDIR}"/board-info.txt
find "${OUTDIR}"/tz* -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> "${WORK_TMPDIR}"/board-info.txt
if [ -e "${OUTDIR}"/vendor/build.prop ]; then
	strings "${OUTDIR}"/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> "${WORK_TMPDIR}"/board-info.txt
fi
sort -u < "${WORK_TMPDIR}"/board-info.txt > "${OUTDIR}"/board-info.txt

# set variables
[[ $(find "$(pwd)"/system "$(pwd)"/system/system "$(pwd)"/vendor "$(pwd)"/*product -maxdepth 1 -type f -name "build*.prop" 2>/dev/null | sort -u | gawk '{print $NF}') ]] || { printf "No system/vendor/product build*.prop found, pushing cancelled.\n" && exit 1; }

flavor=$(prop_get \
	"ro.build.flavor:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.flavor:vendor/build*.prop" \
	"ro.system.build.flavor:{system,system/system}/build*.prop" \
	"ro.build.type:{system,system/system}/build*.prop" \
)
release=$(prop_get \
	"ro.build.version.release:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.version.release:vendor/build*.prop" \
	"ro.system.build.version.release:{system,system/system}/build*.prop" \
)
id=$(prop_get \
	"ro.build.id:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.id:vendor/build*.prop" \
	"ro.system.build.id:{system,system/system}/build*.prop" \
)
tags=$(prop_get \
	"ro.build.tags:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.tags:vendor/build*.prop" \
	"ro.system.build.tags:{system,system/system}/build*.prop" \
)
platform=$(prop_get \
	"ro.board.platform:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.board.platform:vendor/build*.prop" \
	"ro.system.board.platform:{system,system/system}/build*.prop" \
)
manufacturer=$(prop_get \
	"ro.product.manufacturer:{system,system/system,vendor}/build*.prop" \
	"ro.product.brand.sub:system/system/euclid/my_product/build*.prop" \
	"ro.vendor.product.manufacturer:vendor/build*.prop" \
	"ro.product.vendor.manufacturer:vendor/build*.prop" \
	"ro.system.product.manufacturer:{system,system/system}/build*.prop" \
	"ro.product.system.manufacturer:{system,system/system}/build*.prop" \
	"ro.product.odm.manufacturer:vendor/odm/etc/build*.prop" \
	"ro.product.manufacturer:{oppo_product,my_product,product}/build*.prop" \
	"ro.product.manufacturer:vendor/euclid/*/build.prop" \
	"ro.system.product.manufacturer:vendor/euclid/*/build.prop" \
	"ro.product.product.manufacturer:vendor/euclid/product/build*.prop" \
	"ro.product.vendor.manufacturer:vendor/build*.prop" \
	"ro.product.system.manufacturer:{system,system/system}/build*.prop" \
)
fingerprint=$(prop_get \
	"ro.build.fingerprint:{system,system/system}/build*.prop" \
	"ro.vendor.build.fingerprint:vendor/build*.prop" \
	"ro.system.build.fingerprint:{system,system/system}/build*.prop" \
	"ro.product.build.fingerprint:product/build*.prop" \
	"ro.build.fingerprint:{oppo_product,my_product}/build*.prop" \
	"ro.system.build.fingerprint:my_product/build.prop" \
	"ro.vendor.build.fingerprint:my_product/build.prop" \
	"ro.bootimage.build.fingerprint:vendor/build.prop" \
)
brand=$(prop_get \
	"ro.product.brand:{system,system/system,vendor}/build*.prop" \
	"ro.product.brand.sub:system/system/euclid/my_product/build*.prop" \
	"ro.product.vendor.brand:vendor/build*.prop" \
	"ro.vendor.product.brand:vendor/build*.prop" \
	"ro.product.system.brand:{system,system/system}/build*.prop" \
)
# OPPO brand override: prefer euclid value if brand is empty or "OPPO"
[[ -z "${brand}" || "${brand}" == "OPPO" ]] && brand=$(prop_get "ro.product.system.brand:vendor/euclid/*/build.prop")
[[ -z "${brand}" ]] && brand=$(prop_get \
	"ro.product.product.brand:vendor/euclid/product/build*.prop" \
	"ro.product.odm.brand:vendor/odm/etc/build*.prop" \
	"ro.product.brand:{oppo_product,my_product}/build*.prop" \
	"ro.product.brand:vendor/euclid/*/build.prop" \
)
[[ -z "${brand}" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1)
codename=$(prop_get \
	"ro.product.device:{vendor,system,system/system}/build*.prop" \
	"ro.vendor.product.device.oem:vendor/euclid/odm/build.prop" \
	"ro.product.vendor.device:vendor/build*.prop" \
	"ro.vendor.product.device:vendor/build*.prop" \
	"ro.product.system.device:{system,system/system}/build*.prop" \
	"ro.product.system.device:vendor/euclid/*/build.prop" \
	"ro.product.product.device:vendor/euclid/*/build.prop" \
	"ro.product.product.model:vendor/euclid/*/build.prop" \
	"ro.product.device:{oppo_product,my_product}/build*.prop" \
	"ro.product.product.device:oppo_product/build*.prop" \
	"ro.product.system.device:my_product/build*.prop" \
	"ro.product.vendor.device:my_product/build*.prop" \
)
[[ -z "${codename}" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d'-' -f1 | head -1)
[[ -z "${codename}" ]] && codename=$(prop_get "ro.build.product:{vendor,system,system/system}/build*.prop")
description=$(prop_get \
	"ro.build.description:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.description:vendor/build*.prop" \
	"ro.system.build.description:{system,system/system}/build*.prop" \
	"ro.product.build.description:product/build.prop" \
	"ro.product.build.description:product/build*.prop" \
)
incremental=$(prop_get \
	"ro.build.version.incremental:{system,system/system,vendor}/build*.prop" \
	"ro.vendor.build.version.incremental:vendor/build*.prop" \
	"ro.system.build.version.incremental:{system,system/system}/build*.prop" \
	"ro.build.version.incremental:my_product/build*.prop" \
	"ro.system.build.version.incremental:my_product/build*.prop" \
	"ro.vendor.build.version.incremental:my_product/build*.prop" \
)
# For Realme devices with empty incremental & fingerprint,
[[ -z "${incremental}" && "${brand}" =~ "realme" ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.ota=).*" -hs {vendor/euclid/product,oppo_product}/build.prop | rev | cut -d'_' -f'1-2' | rev)
[[ -z "${incremental}" && -n "${description}" ]] && incremental=$(echo "${description}" | cut -d' ' -f4)
[[ -z "${description}" && -n "${incremental}" ]] && description="${flavor} ${release} ${id} ${incremental} ${tags}"
[[ -z "${description}" && -z "${incremental}" ]] && description="${codename}"
abilist=$(prop_get \
	"ro.product.cpu.abilist:{system,system/system}/build*.prop" \
	"ro.vendor.product.cpu.abilist:vendor/build*.prop" \
)
locale=$(prop_get "ro.product.locale:{system,system/system}/build*.prop")
[[ -z "${locale}" ]] && locale=undefined
density=$(prop_get "ro.sf.lcd_density:{system,system/system}/build*.prop")
[[ -z "${density}" ]] && density=undefined
is_ab=$(prop_get "ro.build.ab_update:{system,system/system,vendor}/build*.prop")
[[ -z "${is_ab}" ]] && is_ab="false"
treble_support=$(prop_get "ro.treble.enabled:{system,system/system}/build*.prop")
[[ -z "${treble_support}" ]] && treble_support="false"
otaver=$(prop_get \
	"ro.build.version.ota:{vendor/euclid/product,oppo_product,system,system/system}/build*.prop" \
)
[[ -n "${otaver}" && -z "${fingerprint}" ]] && branch="${otaver// /-}"
[[ -z "${otaver}" ]] && otaver=$(prop_get "ro.build.fota.version:{system,system/system}/build*.prop")
[[ -z "${branch}" ]] && branch="${description// /-}"

# Vendor-specific overrides — these refine values from the initial pass above
prop_override platform \
	"ro.vendor.mediatek.platform:vendor/build.prop" \
	"ro.board.platform:vendor/build.prop"
manufacturer=$(grep -hoP "(?<=^ro.product.odm.brand=).*" {odm/etc/*/build.default.prop,vendor/odm/etc/build.prop,odm/etc/build.prop,my_manifest/build.prop} 2>/dev/null | tail -1 || echo "$manufacturer")
codename=$(grep -hoP "(?<=^ro.product.odm.model=).*" my_manifest/build.prop 2>/dev/null | tail -1 | tr ' ' '-' || true)
codename=${codename:-$(grep -hoP "(?<=^ro.product.odm.device=).*" {odm/etc/*/build.default.prop,vendor/odm/etc/build.prop,odm/etc/build.prop,my_manifest/build.prop} 2>/dev/null | tail -1 | tr ' ' '-')}
prop_override fingerprint \
	"ro.product.build.fingerprint:product/etc/build.prop" \
	"ro.build.fingerprint:my_manifest/build.prop" \
	"ro.tr_product.build.fingerprint:tr_product/etc/build.prop" \
	"ro.build.fingerprint:tr_manifest/build.prop"
[[ -z "$fingerprint" ]] && prop_override fingerprint "ro.tr_region.build.fingerprint:tr_region/etc/build.prop"
prop_override brand "ro.product.system_ext.brand:system_ext/etc/build.prop"
prop_override density "ro.sf.lcd_density:{vendor,system,system/system}/build*.prop"
transname=$(prop_get "ro.product.product.tran.device.name.default:product/etc/build.prop")
osver=$(prop_get "ro.os.version.release:product/etc/build.prop")
xosver=$(prop_get \
	"ro.tranos.version:product/etc/build.prop" \
	"ro.tranos.version:tr_product/etc/build.prop" \
)
sec_patch=$(prop_get "ro.build.version.security_patch:{system,system/system}/build*.prop")
xosid=$(prop_get \
	"ro.build.display.id:tr_region/etc/build.prop" \
	"ro.build.display.id:tr_product/etc/build.prop" \
	"ro.build.display.id:product/etc/build.prop" \
)
[[ -n "$xosid" ]] && branch="${xosid// /-}"

for overlay in TranSettingsApkResOverlay ItelSettingsResOverlay; do
  file="product/overlay/${overlay}/${overlay}.apk"
  if [ -f "$file" ]; then
    apktool d "$file"
    tranchipset="$(grep -oP '(?<=<string name="cpu_rate_cores">).*(?=</string>)' -ar ${overlay}/res/values/strings.xml)"
    rm -rf "${overlay}"
    break
  fi
done
[ -z "${tranchipset}" ] && tranchipset=$(cat tr_product/etc/asset/transettings/cpu_info)

CPU_MODEL=$(grep "ro.product.oplus.cpuinfo=" my_product/build.prop | head -n 1 | cut -d'=' -f2)
opchipset=$(grep "model_name=\"$CPU_MODEL\"" my_stock/etc/extension/config_processor_com.android.settings.xml | grep -Po '(?<=name_en=")[^"]*')

repo=$(printf "${manufacturer}" && echo -e "/${codename}")

kernel_version=$(strings boot/kernel | grep -m1 -oP 'Linux version \K[\d.]+-[\w-]+')
[ -z "$kernel_version" ] && kernel_version=$(strings boot/kernel | grep -oP '\b[0-9]+\.[0-9]+\.[0-9]+-[\w.-]+' | tail -n1) && kernel_version=${kernel_version::-1}
[ -z "$kernel_version" ] && kernel_version=$(zcat boot/kernel | strings | grep -i Android | grep -oP '\b[0-9]+\.[0-9]+\.[0-9]+-[\w.-]+' | tail -n1)

date=$(grep -m1 -oP "(?<=^ro.build.date=).*" -hs tr_manifest/build.prop | head -1)

# Repo README File
cat <<EOF > "${OUTDIR}"/README.md
## FIRMWARE DUMP
### ${description}
EOF

for trfile in tr_product/overlay/com_transsion_overlaysuw/*.apk; do
  [ -e "$trfile" ] || continue

  outdir="decoded_overlay"
  apktool d "$trfile" -o "$outdir" -f

  transname="$(grep -oP '(?<=<item>DEFAULT/)[^<]+' "$outdir/res/values/arrays.xml")"

  rm -rf "$outdir"
  break
done
if [ -z "${transname}" ] && [ -f "odm/etc/goldwatermark/configs/TranssionWM.json" ]; then
    transname="$(grep -oP '(?<=TEXT_BRAND_NAME": ")[^"]*' odm/etc/goldwatermark/configs/TranssionWM.json | head -n1 | xargs)"
fi

if [ -z "${transname}" ] && [ -f "odm/etc/asset/camera/goldwatermark/configs/TranssionWM.json" ]; then
    transname="${manufacturer} $(grep -oP '(?<=TEXT_BRAND_NAME": ")[^"]*' odm/etc/asset/camera/goldwatermark/configs/TranssionWM.json | head -n1 | xargs)"
fi

xiaominame=$(grep -rhs -oP "(?<=^ro.product.odm.marketname=).*" {odm,vendor/odm}/etc/ 2>/dev/null | grep -v '^[a-z]*$' | sort -u | paste -sd '|' | sed 's/|/ | /g')

[ ! -n "${xiaominame}" ] && motoname=$(grep -hs "^ro\.product\..*\.model=" */etc/build.prop system/system/build.prop product/etc/motorola/props/*.prop | cut -d= -f2 | tr -d '\r' | awk '{$1=$1};1' | grep -i "moto" | sort -u | paste -sd "|" - | sed 's/|/ | /g')

opname=$(grep -hoP "(?<=^ro.vendor.oplus.market.name=).*" my_manifest/build.prop)

outfile="${OUTDIR}/README.md"

[ -n "${transname}" ]      && echo "- Transsion name: ${transname}" >> "$outfile"
[ -n "${xiaominame}" ]      && echo "- Xiaomi name: ${xiaominame}" >> "$outfile"
[ -n "${motoname}" ]      && echo "- Moto name: ${motoname}" >> "$outfile"
[ -n "${opname}" ]      && echo "- OP name: ${opname}" >> "$outfile"
[ -n "${xosid}" ]          && echo "- TranOS build: ${xosid}" >> "$outfile"
[ -n "${xosver}" ]         && echo "- TranOS version: ${xosver}" >> "$outfile"
[ -n "${manufacturer}" ]   && echo "- Brand: ${manufacturer}" >> "$outfile"
[ -n "${codename}" ]       && echo "- Model: ${codename}" >> "$outfile"

if [ -n "${platform}" ]; then
    if [[ "${platform}" == *"ums"* ]] && [ -n "${tranchipset}" ]; then
        echo "- Platform: ${tranchipset}" >> "$outfile"
    elif [ -n "${tranchipset}" ]; then
        echo "- Platform: ${platform} (${tranchipset})" >> "$outfile"
    elif [ -n "${opchipset}" ]; then
        echo "- Platform: ${platform} (${opchipset})" >> "$outfile"
    else
        echo "- Platform: ${platform}" >> "$outfile"
    fi
fi

[ -n "${id}" ]             && echo "- Android build: ${id}" >> "$outfile"
[ -n "${release}" ]        && echo "- Android version: ${release}" >> "$outfile"
[ -n "${kernel_version}" ] && echo "- Kernel version: ${kernel_version}" >> "$outfile"
[ -n "${sec_patch}" ]      && echo "- Security patch: ${sec_patch}" >> "$outfile"
[ -n "${abilist}" ]        && echo "- CPU abilist: ${abilist}" >> "$outfile"
[ -n "${is_ab}" ]          && echo "- A/B device: ${is_ab}" >> "$outfile"
[ -n "${treble_support}" ] && echo "- Treble device: ${treble_support}" >> "$outfile"
[ -n "${density}" ]        && echo "- Screen density: ${density}" >> "$outfile"
[ -n "${fingerprint}" ]    && echo "- Fingerprint: ${fingerprint}" >> "$outfile"
[ -n "${date}" ]    && echo "- Build date: ${date}" >> "$outfile"

cat "$outfile"

echo -e "\nrepo: $repo\n"

if [[ "${README_ONLY}" == "true" ]]; then
	printf "\nREADME.md generated. Skipping Tree generation & Pushing.\n"
	exit 0
fi

# Generate TWRP Trees
twrpdtout="twrp-device-tree"
if [[ "$is_ab" = true ]]; then
	if [ -f recovery.img ]; then
		printf "Legacy A/B with recovery partition detected...\n"
		twrpimg="recovery.img"
	else
	twrpimg="vendor_boot.img"
	fi
else
	twrpimg="recovery.img"
fi
if [[ -f ${twrpimg} ]]; then
    mkdir -p $twrpdtout
    uvx --from git+https://github.com/twrpdtgen/twrpdtgen@master twrpdtgen $twrpimg -o $twrpdtout
    if [[ "$?" -eq 0 ]]; then
        [[ ! -e "${twrpdtout}/README.md" ]] && curl https://raw.githubusercontent.com/wiki/SebaUbuntu/TWRP-device-tree-generator/4.-Build-TWRP-from-source.md > ${twrpdtout}/README.md
    elif [[ -f "vendor_boot.img" ]]; then
        uvx --from git+https://github.com/twrpdtgen/twrpdtgen@master twrpdtgen vendor_boot.img -o $twrpdtout
        [[ "$?" -eq 0 && ! -e "${twrpdtout}/README.md" ]] && curl https://raw.githubusercontent.com/wiki/SebaUbuntu/TWRP-device-tree-generator/4.-Build-TWRP-from-source.md > ${twrpdtout}/README.md
    fi
fi

# Remove all .git directories from twrpdtout
find "$twrpdtout" -type d -name ".git" -exec rm -rf {} +

# copy file names
chown "$(whoami)" ./* -R
chmod -R u+rwX ./*		#ensure final permissions
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

# Regenerate all_files.txt
printf "Generating all_files.txt...\n"
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

rm -rf "${WORK_TMPDIR}" 2>/dev/null

if [[ "${MODE}" == "gitlab" ]]; then
if [[ -n "${GITLAB_TOKEN}" ]]; then

	retry_push() { while ! git push "$@"; do echo "Retrying..."; sleep 2; done; }

	push_lfs_objects() {
		git lfs ls-files --all -l | awk '{print $1}' | while read -r oid; do
			echo "Pushing LFS object: $oid"
			while ! git lfs push --object-id origin "$oid"; do
				echo "Retrying LFS object $oid..."
				sleep 5
				done
			echo "✓ $oid done"
		done
	}

	commit_and_push(){
		local DIRS=(
			"system_ext"
			"product"
			"system_dlkm"
			"odm"
			"odm_dlkm"
			"init_boot"
			"vendor_boot"
			"vendor_dlkm"
			"vendor"
			"system"
			"tr_product"
			"tr_region"
		)

		git add README.md
		git commit -sm "Add README.md for ${description}"
		retry_push -f origin "${branch}"

		git lfs install
		[ -e ".gitattributes" ] || find . -type f -not -path ".git/*" -size +100M | \
			sed 's|.*/||' | sort -u | \
			xargs -I{} git lfs track "{}"
		[ -e ".gitattributes" ] && {
			git add ".gitattributes"
			git commit -sm "Setup Git LFS"
			retry_push -u origin "${branch}"
		}

		find . -type f -name '*.apk' -exec git add {} +
		git commit -sm "Add apps for ${description}"
		push_lfs_objects
		retry_push -u origin "${branch}"

		for i in "${DIRS[@]}"; do
			[ -d "${i}" ] && git add "${i}"
			[ -d system/"${i}" ] && git add system/"${i}"
			[ -d system/system/"${i}" ] && git add system/system/"${i}"
			[ -d vendor/"${i}" ] && git add vendor/"${i}"

			git commit -sm "Add ${i} for ${description}"
			retry_push -u origin "${branch}"
		done

		git add .
		git commit -sm "Add extras for ${description}"
		retry_push -u origin "${branch}"
	}

	GIT_ORG="${GITLAB_GROUP}"	# Set Your Gitlab Group Name

	# Gitlab Vars
	# GITLAB_TOKEN is already sourced from .dumprxenv
	if [[ -z "${GITLAB_INSTANCE}" ]]; then
		GITLAB_INSTANCE="gitlab.com"
	fi
	GITLAB_HOST="https://${GITLAB_INSTANCE}"

	# Check if already dumped or not
	[[ $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]] && { printf "Firmware already dumped!\nGo to https://%s/%s/%s/-/tree/%s\n" "${GITLAB_INSTANCE}" "${GIT_ORG}" "${repo}" "${branch}" && exit 1; }

	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"

	git init		# Ensure Your GitLab Authorization Before Running This Script
	git config http.postBuffer 524288000		# Local config only — avoids mutating user's global git config
	git checkout -b "${branch}" || { git checkout -b "${incremental}" && export branch="${incremental}"; }
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	[[ -z "$(git config --get user.email)" ]] && git config user.email "ramanarubp@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Rama Bondan Prakoso"

	# Create Subgroup
	GRP_ID=$(curl -s --request GET --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}" | jq -r '.id')
	if [[ -z "${GRP_ID}" || "${GRP_ID}" == "null" ]]; then
		printf "Error: Could not find GitLab group '%s'. Check GITLAB_GROUP in .dumprxenv\n" "${GIT_ORG}"
		exit 1
	fi
	mfr_lower=$(echo "${manufacturer}" | tr '[:upper:]' '[:lower:]')
	curl --request POST \
	--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
	--header "Content-Type: application/json" \
	--data '{"name": "'"${manufacturer}"'", "path": "'"${mfr_lower}"'", "visibility": "public", "parent_id": "'"${GRP_ID}"'"}' \
	"${GITLAB_HOST}/api/v4/groups/"
	echo ""

	# Subgroup ID
	# Look up subgroup ID by name using jq — no temp files, no race conditions
	get_gitlab_id_by_path() {
		# Usage: get_gitlab_id_by_path <api_url> <path_to_match>
		local api_url="$1" match_path="$2"
		match_path=$(echo "${match_path}" | tr '[:upper:]' '[:lower:]')
		curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${api_url}" \
			| jq -r --arg p "${match_path}" '.[] | select(.path == $p) | .id'
	}

	SUBGRP_ID=$(get_gitlab_id_by_path "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}/subgroups" "${manufacturer}")
	if [[ -z "${SUBGRP_ID}" ]]; then
		printf "Error: Could not find subgroup for manufacturer '%s'\n" "${manufacturer}"
		exit 1
	fi

	# Create Repository
	curl -s \
	--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
	-X POST \
	"${GITLAB_HOST}/api/v4/projects?name=${codename}&namespace_id=${SUBGRP_ID}&visibility=public"

	# Get Project/Repo ID — reuse the same jq-based lookup
	PROJECT_ID=$(get_gitlab_id_by_path "${GITLAB_HOST}/api/v4/groups/${SUBGRP_ID}/projects" "${codename}")
	if [[ -z "${PROJECT_ID}" ]]; then
		printf "Error: Could not find project '%s' in subgroup %s\n" "${codename}" "${SUBGRP_ID}"
		exit 1
	fi

	# Commit and Push
	# Pushing via HTTPS doesn't work on GitLab for Large Repos (it's an issue with gitlab for large repos)
	# NOTE: Your SSH Keys Needs to be Added to your Gitlab Instance
	git remote add origin "git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git"

	# Ensure that the target repo is public
	REPO_DESC="${codename}"
	[[ -n "${transname}" ]] && REPO_DESC="${transname}"
	curl --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --url "${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}" --data "visibility=public" --data-urlencode "description=${REPO_DESC}"
	printf "\n"

	# Push to GitLab
	while ! git ls-remote --exit-code origin "${branch}" >/dev/null 2>&1 || ! git diff --quiet origin/"${branch}" HEAD -- all_files.txt 2>/dev/null
	do
		printf "\nPushing to %s via SSH...\nBranch:%s\n" "${GITLAB_HOST}/${GIT_ORG}/${repo}.git" "${branch}"
		sleep 1
		commit_and_push
		sleep 1
	done

	# Update the Default Branch
	curl	--request PUT \
		--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
		--url "${GITLAB_HOST}/api/v4/projects/${PROJECT_ID}" \
		--data "default_branch=${branch}"
	printf "\n"

	# Telegram channel post
	if [[ -n "${TG_TOKEN}" ]]; then
		if [[ -n "${TG_CHAT}" ]]; then		# TG Channel ID
			CHAT_ID="${TG_CHAT}"
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<blockquote><b>FIRMWARE DUMP INFO</b></blockquote>" >| "${OUTDIR}"/tg.html
		{
			[ ! -z "${transname}" ] && printf "\n<b>Transsion name: %s</b>" "<code>${transname}</code>"
			[ ! -z "${xiaominame}" ] && printf "\n<b>Xiaomi name: %s</b>" "<code>${xiaominame}</code>"
			[ ! -z "${motoname}" ] && printf "\n<b>Moto name: %s</b>" "<code>${motoname}</code>"
			[ ! -z "${opname}" ] && printf "\n<b>OP name: %s</b>" "<code>${opname}</code>"
			[ ! -z "${xosid}" ] && printf "\n<b>TranOS build: %s</b>" "<code>${xosid}</code>"
			[ ! -z "${xosver}" ] && printf "\n<b>TranOS ver: %s</b>" "<code>${xosver}</code>"
			printf "\n<b>Brand: %s</b>" "<code>${manufacturer}</code>"
			printf "\n<b>Model: %s</b>" "<code>${codename}</code>"
			printf "\n<b>Platform: %s</b>" "<code>${platform}${ts_chipset}</code>"
			printf "\n<b>Android build: %s</b>" "<code>${id}</code>"
			printf "\n<b>Android ver: %s</b>" "<code>${release}</code>"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel ver: %s</b>" "<code>${kernel_version}</code>"
			printf "\n<b>Security patch: %s</b>" "<code>${sec_patch}</code>"
			printf "\n<b>Fingerprint: %s</b>" "<code>${fingerprint}</code>"
			printf "\n<a href=\"${GITLAB_HOST}/%s/%s/-/tree/%s/\">Gitlab Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

else
	printf "GitLab mode selected but gitlab token is missing.\n"
	exit 1
fi
else
	printf "Dumping done locally.\n"
	exit
fi
