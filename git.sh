#!/bin/bash

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Sanitize And Generate Folders
OUTDIR=/tmp/out			# Contains Final Extracted Files

cd $OUTDIR

flavor=$(grep -m1 -oP "(?<=^ro.build.flavor=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.vendor.build.flavor=).*" -hs vendor/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.system.build.flavor=).*" -hs {system,system/system}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.build.type=).*" -hs {system,system/system}/build*.prop)
release=$(grep -m1 -oP "(?<=^ro.build.version.release=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${release}" ]] && release=$(grep -m1 -oP "(?<=^ro.vendor.build.version.release=).*" -hs vendor/build*.prop)
[[ -z "${release}" ]] && release=$(grep -m1 -oP "(?<=^ro.system.build.version.release=).*" -hs {system,system/system}/build*.prop)
id=$(grep -m1 -oP "(?<=^ro.build.id=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${id}" ]] && id=$(grep -m1 -oP "(?<=^ro.vendor.build.id=).*" -hs vendor/build*.prop)
[[ -z "${id}" ]] && id=$(grep -m1 -oP "(?<=^ro.system.build.id=).*" -hs {system,system/system}/build*.prop)
tags=$(grep -m1 -oP "(?<=^ro.build.tags=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -m1 -oP "(?<=^ro.vendor.build.tags=).*" -hs vendor/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -m1 -oP "(?<=^ro.system.build.tags=).*" -hs {system,system/system}/build*.prop)
platform=$(grep -m1 -oP "(?<=^ro.board.platform=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${platform}" ]] && platform=$(grep -m1 -oP "(?<=^ro.vendor.board.platform=).*" -hs vendor/build*.prop)
[[ -z "${platform}" ]] && platform=$(grep -m1 -oP "(?<=^ro.system.board.platform=).*" -hs {system,system/system}/build*.prop)
manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.vendor.product.manufacturer=).*" -hs vendor/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.vendor.manufacturer=).*" -hs vendor/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.system.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.odm.manufacturer=).*" -hs vendor/odm/etc/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {oppo_product,my_product,product}/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.product.manufacturer=).*" -hs vendor/euclid/product/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.vendor.manufacturer=).*" -hs vendor/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.system.manufacturer=).*" -hs {system,system/system}/build*.prop)
fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs vendor/build*.prop | head -1)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.product.build.fingerprint=).*" -hs product/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs {oppo_product,my_product}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.bootimage.build.fingerprint=).*" -hs vendor/build.prop)
brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.vendor.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.vendor.product.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${brand}" || ${brand} == "OPPO" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.product.brand=).*" -hs vendor/euclid/product/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${brand}" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1)
codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device.oem=).*" -hs vendor/euclid/odm/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.model=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs oppo_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d'-' -f1 | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.build.product=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
description=$(grep -m1 -oP "(?<=^ro.build.description=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build*.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.system.build.description=).*" -hs {system,system/system}/build*.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build*.prop)
incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs vendor/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs my_product/build*.prop)
# For Realme devices with empty incremental & fingerprint,
[[ -z "${incremental}" && "${brand}" =~ "realme" ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.ota=).*" -hs {vendor/euclid/product,oppo_product}/build.prop | rev | cut -d'_' -f'1-2' | rev)
[[ -z "${incremental}" && ! -z "${description}" ]] && incremental=$(echo "${description}" | cut -d' ' -f4)
[[ -z "${description}" && ! -z "${incremental}" ]] && description="${flavor} ${release} ${id} ${incremental} ${tags}"
[[ -z "${description}" && -z "${incremental}" ]] && description="${codename}"
abilist=$(grep -m1 -oP "(?<=^ro.product.cpu.abilist=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${abilist}" ]] && abilist=$(grep -m1 -oP "(?<=^ro.vendor.product.cpu.abilist=).*" -hs vendor/build*.prop)
locale=$(grep -m1 -oP "(?<=^ro.product.locale=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${locale}" ]] && locale=undefined
density=$(grep -m1 -oP "(?<=^ro.sf.lcd_density=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${density}" ]] && density=undefined
is_ab=$(grep -m1 -oP "(?<=^ro.build.ab_update=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${is_ab}" ]] && is_ab="false"
treble_support=$(grep -m1 -oP "(?<=^ro.treble.enabled=).*" -hs {system,system/system}/build*.prop)
[[ -z "${treble_support}" ]] && treble_support="false"
otaver=$(grep -m1 -oP "(?<=^ro.build.version.ota=).*" -hs {vendor/euclid/product,oppo_product,system,system/system}/build*.prop | head -1)
[[ ! -z "${otaver}" && -z "${fingerprint}" ]] && branch=$(echo "${otaver}" | tr ' ' '-')
[[ -z "${otaver}" ]] && otaver=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${branch}" ]] && branch=$(echo "${description}" | tr ' ' '-')

if false; then
# Transsions vars
platform=$(grep -m1 -oP "(?<=^ro.vendor.mediatek.platform=).*" -hs vendor/build.prop | head -1 || echo "$platform")
manufacturer=$(grep -m1 -oP "(?<=^ro.product.system_ext.manufacturer=).*" -hs system_ext/etc/build.prop | head -1 || echo "$manufacturer")
fingerprint=$(grep -m1 -oP "(?<=^ro.tr_product.build.fingerprint=).*" -hs tr_product/etc/build.prop || echo "$fingerprint")
fingerprint=$(grep -m1 -oP "(?<=^ro.tr_product.build.fingerprint=).*" -hs product/etc/build.prop || echo "$fingerprint")
brand=$(grep -m1 -oP "(?<=^ro.product.system_ext.brand=).*" -hs system_ext/etc/build.prop | head -1 || echo "$brand")
codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs product/etc/build.prop | head -1 || echo "$codename")
density=$(grep -m1 -oP "(?<=^ro.sf.lcd_density=).*" -hs {vendor,system,system/system}/build*.prop | head -1 || echo "$density")
transname=$(grep -m1 -oP "(?<=^ro.product.product.tran.device.name.default=).*" -hs product/etc/build.prop | head -1)
osver=$(grep -m1 -oP "(?<=^ro.os.version.release=).*" -hs product/etc/build.prop | head -1)
xosver=$(grep -m1 -oP "(?<=^ro.tranos.version=).*" -hs product/etc/build.prop | head -1)
sec_patch=$(grep -m1 -oP "(?<=^ro.build.version.security_patch=).*" -hs {system,system/system}/build*.prop | head -1)
xosid=$(grep -m1 -oP "(?<=^ro.build.display.id=).*" -hs tr_product/etc/build.prop | head -1)
[[ -z "${xosid}" ]] && xosid=$(grep -m1 -oP "(?<=^ro.build.display.id=).*" -hs product/etc/build.prop | head -1)

for overlay in TranSettingsApkResOverlay ItelSettingsResOverlay; do
  file="product/overlay/${overlay}/${overlay}.apk"
  if [ -f "$file" ]; then
    apktool d "$file"
    tranchipset=" ($(grep -oP '(?<=<string name="cpu_rate_cores">).*(?=</string>)' -ar ${overlay}/res/values/strings.xml))"
    rm -rf "${overlay}"
    break
  fi
done
else
platform=$(grep -m1 -oP "(?<=^ro.vendor.mediatek.platform=).*" -hs vendor/build.prop | head -1 || echo "$platform")
brand=$(grep -m1 -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build_* | head -1 || echo "$brand")
manufacturer=$(grep -m1 -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build_* | head -1 || echo "$manufacturer")
codename=$(grep -m1 -oP "(?<=^ro.product.odm.device=).*" -hs vendor/odm/etc/build_* | head -1 || echo "$codename")
miname=$(grep -m1 -oP "(?<=^ro.product.odm.marketname=).*" -hs vendor/odm/etc/build_* | head -1)
density=$(grep -m1 -oP "(?<=^ro.sf.lcd_density=).*" -hs product/etc/build.prop | head -1 || echo "$density")
fingerprint=$(grep -m1 -oP "(?<=^ro.odm.build.fingerprint=).*" -hs vendor/odm/etc/build_*gl* | head -1 || echo "$fingerprint")
fi

if [[ "$PUSH_TO_GITLAB" = true ]]; then
	rm -rf .github_token
	repo=$(printf "${brand}" | tr '[:upper:]' '[:lower:]' && echo -e "/${codename}")
else
	rm -rf .gitlab_token
#	repo=$(printf "${brand}" | tr '[:upper:]' '[:lower:]' && echo -e "/${codename}")
	repo=$(echo "${brand}/${codename}")
fi

platform=$(echo "${platform}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
#top_codename=$(echo "${codename}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
#manufacturer=$(echo "${manufacturer}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
[ -f "bootRE/ikconfig" ] && kernel_version=$(cat bootRE/ikconfig | grep "Kernel Configuration" | head -1 | awk '{print $3}')
# Repo README File
cat <<EOF > "${OUTDIR}"/README.md
## FIRMWARE DUMP
### ${description}
EOF

[ ! -z "${transname}" ] && echo "- Transsion name: ${transname}" >> "${OUTDIR}"/README.md
[ ! -z "${miname}" ] && echo "- Device name: ${miname}" >> "${OUTDIR}"/README.md
[ ! -z "${xosid}" ] && echo "- TranOS build: ${xosid}" >> "${OUTDIR}"/README.md
[ ! -z "${xosver}" ] && echo "- TranOS version: ${xosver}" >> "${OUTDIR}"/README.md
[ ! -z "${manufacturer}" ] && echo "- Brand: ${manufacturer}" >> "${OUTDIR}"/README.md
[ ! -z "${codename}" ] && echo "- Model: ${codename}" >> "${OUTDIR}"/README.md
[ ! -z "${platform}" ] && echo "- Platform: ${platform}${tranchipset}" >> "${OUTDIR}"/README.md
[ ! -z "${id}" ] && echo "- Android build: ${id}" >> "${OUTDIR}"/README.md
[ ! -z "${release}" ] && echo "- Android version: ${release}" >> "${OUTDIR}"/README.md
[ ! -z "${kernel_version}" ] && echo "- Kernel version: ${kernel_version}" >> "${OUTDIR}"/README.md
[ ! -z "${sec_patch}" ] && echo "- Security patch: ${sec_patch}" >> "${OUTDIR}"/README.md
[ ! -z "${abilist}" ] && echo "- CPU abilist: ${abilist}" >> "${OUTDIR}"/README.md
[ ! -z "${is_ab}" ] && echo "- A/B device: ${is_ab}" >> "${OUTDIR}"/README.md
[ ! -z "${treble_support}" ] && echo "- Treble device: ${treble_support}" >> "${OUTDIR}"/README.md
[ ! -z "${density}" ] && echo "- Screen density: ${density}" >> "${OUTDIR}"/README.md
[ ! -z "${fingerprint}" ] && echo "- Fingerprint: ${fingerprint}" >> "${OUTDIR}"/README.md

cat "${OUTDIR}"/README.md

# Regenerate all_files.txt
printf "Generating all_files.txt...\n"
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

retry_push() { while ! git push "$@"; do echo "Retrying..."; sleep 2; done; }

commit_and_push(){
	local DIRS=(
		"system_ext"
		"product"
		"system_dlkm"
		"odm"
		"odm_dlkm"
		"vendor_dlkm"
		"vendor"
		"system"
	)

	git add README.md
	git commit -sm "Add README.md for ${description}"
	retry_push -f origin "${branch}"

	git lfs install
	[ -e ".gitattributes" ] || find . -type f -not -path ".git/*" -size +100M -exec git lfs track {} \;
	[ -e ".gitattributes" ] && {
		git add ".gitattributes"
		git commit -sm "Setup Git LFS"
		git push -u origin "${branch}"
	}

	git add $(find -type f -name '*.apk')
	git commit -sm "Add apps for ${description}"
	git push -u origin "${branch}"

	for i in "${DIRS[@]}"; do
		[ -d "${i}" ] && git add "${i}"
		[ -d system/"${i}" ] && git add system/"${i}"
		[ -d system/system/"${i}" ] && git add system/system/"${i}"
		[ -d vendor/"${i}" ] && git add vendor/"${i}"

		git commit -sm "Add ${i} for ${description}"
		git push -u origin "${branch}"
	done

	git add .
	git commit -sm "Add extras for ${description}"
	git push -u origin "${branch}"
}


if true; then
if [[ -s "${PROJECT_DIR}"/.github_token ]]; then
	GITHUB_TOKEN=$(< "${PROJECT_DIR}"/.github_token)	# Write Your Github Token In a Text File
	[[ -z "$(git config --get user.email)" ]] && git config user.email "ramanarubp@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Rama Bondan Prakoso"
	if [[ -s "${PROJECT_DIR}"/.github_orgname ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.github_orgname)	# Set Your Github Organization Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi
	# Check if already dumped or not
	curl -sf "https://raw.githubusercontent.com/${GIT_ORG}/${repo}/${branch}/all_files.txt" 2>/dev/null && { printf "Firmware already dumped!\nGo to https://github.com/%s/%s/tree/%s\n" "${GIT_ORG}" "${repo}" "${branch}" && exit 1; }
	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	# Files larger than 62MB will be split into 47MB parts as *.aa, *.ab, etc.
	mkdir -p "${TMPDIR}" 2>/dev/null
	find . -size +62M | cut -d'/' -f'2-' >| "${TMPDIR}"/.largefiles
	if [[ -s "${TMPDIR}"/.largefiles ]]; then
		printf '#!/bin/bash\n\n' > join_split_files.sh
		while read -r l; do
			split -b 47M "${l}" "${l}".
			rm -f "${l}" 2>/dev/null
			printf "cat %s.* 2>/dev/null >> %s\n" "${l}" "${l}" >> join_split_files.sh
			printf "rm -f %s.* 2>/dev/null\n" "${l}" >> join_split_files.sh
		done < "${TMPDIR}"/.largefiles
		chmod a+x join_split_files.sh 2>/dev/null
	fi
	rm -rf "${TMPDIR}" 2>/dev/null
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"
	git init		# Insure Your Github Authorization Before Running This Script
	git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git checkout -b "${branch}" || { git checkout -b "${incremental}" && export branch="${incremental}"; }
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	if [[ "${GIT_ORG}" == "${GIT_USER}" ]]; then
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{"name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/user/repos" >/dev/null 2>&1
	else
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{ "name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/orgs/${GIT_ORG}/repos" >/dev/null 2>&1
	fi
	curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"${platform}"'","'"${manufacturer}"'","'"${top_codename}"'","firmware","dump"]}' "https://api.github.com/repos/${GIT_ORG}/${repo}/topics" 	# Update Repository Topics
	
	# Commit and Push
	printf "\nPushing to %s via HTTPS...\nBranch:%s\n" "https://github.com/${GIT_ORG}/${repo}.git" "${branch}"
	sleep 1
	git remote add origin https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
	commit_and_push
	sleep 1
	
	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Platform: %s</b>" "${platform}"
			printf "\n<b>Android Version:</b> %s" "${release}"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel Version:</b> %s" "${kernel_version}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<a href=\"https://github.com/%s/%s/tree/%s/\">Github Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

elif [[ -s "${PROJECT_DIR}"/.gitlab_token ]]; then
	if [[ -s "${PROJECT_DIR}"/.gitlab_group ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.gitlab_group)	# Set Your Gitlab Group Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi

	# Gitlab Vars
	GITLAB_TOKEN=$(< "${PROJECT_DIR}"/.gitlab_token)	# Write Your Gitlab Token In a Text File
	if [ -f "${PROJECT_DIR}"/.gitlab_instance ]; then
		GITLAB_INSTANCE=$(< "${PROJECT_DIR}"/.gitlab_instance)
	else
		GITLAB_INSTANCE="gitlab.com"
	fi
	GITLAB_HOST="https://${GITLAB_INSTANCE}"

	# Check if already dumped or not
	[[ $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]] && { printf "Firmware already dumped!\nGo to https://"$GITLAB_INSTANCE"/${GIT_ORG}/${repo}/-/tree/${branch}\n" && exit 1; }

	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"

	git init		# Insure Your GitLab Authorization Before Running This Script
	git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git checkout -b "${branch}" || { git checkout -b "${incremental}" && export branch="${incremental}"; }
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	[[ -z "$(git config --get user.email)" ]] && git config user.email "ramanarubp@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Rama Bondan Prakoso"

	# Create Subgroup
	GRP_ID=$(curl -s --request GET --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}" | jq -r '.id')
	curl --request POST \
	--header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
	--header "Content-Type: application/json" \
	--data '{"name": "'"${brand}"'", "path": "'"$(echo ${brand} | tr [:upper:] [:lower:])"'", "visibility": "public", "parent_id": "'"${GRP_ID}"'"}' \
	"${GITLAB_HOST}/api/v4/groups/"
	echo ""

	# Subgroup ID
	get_gitlab_subgrp_id(){
		local SUBGRP=$(echo "$1" | tr '[:upper:]' '[:lower:]')
		curl -s --request GET --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}/subgroups" | jq -r .[] | jq -r .path,.id > /tmp/subgrp.txt
		local i
		for i in $(seq "$(cat /tmp/subgrp.txt | wc -l)")
		do
			local TMP_I=$(cat /tmp/subgrp.txt | head -"$i" | tail -1)
			[[ "$TMP_I" == "$SUBGRP" ]] && cat /tmp/subgrp.txt | head -$(("$i"+1)) | tail -1 > "$2"
		done
		}

	get_gitlab_subgrp_id ${brand} /tmp/subgrp_id.txt
	SUBGRP_ID=$(< /tmp/subgrp_id.txt)

	# Create Repository
	curl -s \
	--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
	-X POST \
	"${GITLAB_HOST}/api/v4/projects?name=${codename}&namespace_id=${SUBGRP_ID}&visibility=public"

	# Get Project/Repo ID
	get_gitlab_project_id(){
		local PROJ="$1"
		curl -s --request GET --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST}/api/v4/groups/$2/projects" | jq -r .[] | jq -r .path,.id > /tmp/proj.txt
		local i
		for i in $(seq "$(cat /tmp/proj.txt | wc -l)")
		do
			local TMP_I=$(cat /tmp/proj.txt | head -"$i" | tail -1)
			[[ "$TMP_I" == "$PROJ" ]] && cat /tmp/proj.txt | head -$(("$i"+1)) | tail -1 > "$3"
		done
		}
	get_gitlab_project_id ${codename} ${SUBGRP_ID} /tmp/proj_id.txt
	PROJECT_ID=$(< /tmp/proj_id.txt)

	# Delete the Temporary Files
	rm -rf /tmp/{subgrp,subgrp_id,proj,proj_id}.txt

	# Commit and Push
	# Pushing via HTTPS doesn't work on GitLab for Large Repos (it's an issue with gitlab for large repos)
	# NOTE: Your SSH Keys Needs to be Added to your Gitlab Instance
	git remote add origin git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git

	# Ensure that the target repo is public
	curl --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --url ''"${GITLAB_HOST}"'/api/v4/projects/'"${PROJECT_ID}"'' --data "visibility=public"
	printf "\n"

	# Push to GitLab
	while [[ ! $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]]
	do
		printf "\nPushing to %s via SSH...\nBranch:%s\n" "${GITLAB_HOST}/${GIT_ORG}/${repo}.git" "${branch}"
		sleep 1
		commit_and_push
		sleep 1
	done

	# Update the Default Branch
	curl	--request PUT \
		--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
		--url ''"${GITLAB_HOST}"'/api/v4/projects/'"${PROJECT_ID}"'' \
		--data "default_branch=${branch}"
	printf "\n"

	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<blockquote><b>FIRMWARE DUMP INFO</b></blockquote>" >| "${OUTDIR}"/tg.html
		{
			[ ! -z "${transname}" ] && printf "\n<b>Transsion name: %s</b>" "<code>${transname}</code>"
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
	printf "Dumping done locally.\n"
	exit
fi
else
	printf "Dumping done locally.\n"
	exit
fi
