#!/bin/bash

# this script provides some tool needed to translate the homepage.

# before you can use this script the first time, you have to initialize Transifex in this folder:
# $ tx init --user=api --pass=<your api token>
# you may also need `txt2po`, get it by `sudo apt install translate-toolkik`

# after that, call `./t-dance update` to rebuild all non-english markdown files
# from the translations provided by transifex users

# call `./t-dance push-sources` to request translations for changed in the english markdown files

# the hidden `.tx` folder was generated by the following command:
# $ tx set --auto-remote https://www.transifex.com/projects/p/delta-chat-pages/

# common information about the Transifex CLI client can be found at:
# https://docs.transifex.com/client/


sfiles=(blog contribute download features help imprint index)
tlangs=(de es fr it pt ru sq)  # do not add `en` to this list


tx_pull() {
	rm -r translations
	tx pull -a   # -a = fetch all translationss, -s = fetches source
}


create_markdown_files() {
	for sfile in ${sfiles[@]}; do
		for tlang in ${tlangs[@]}; do
			pofile="../${tlang}/${sfile}.md"
			po2txt --progress=none --template="../en/${sfile}.md" "translations/delta-chat-pages.${sfile}po/${tlang}.po" $pofile
			sed -i "0,/^$/ s/^$/\n\n\n<!-- GENERATED FILE -- DO NOT EDIT -->\n\n\n/" $pofile # add a comment in the first empty line (with `0,/^$/` you select all lines until the re matches)
		done
	done	
}


create_html_files() {
	# if you want to rebuild the html files when markdown is updated,
	# crete the file ./jekyll-build-local.prv.sh with the following content:
	# `cd ..; jekyll build --destination <html-folder>; echo "Options +MultiViews" > <html-folder>/.htaccess; cd tools`  
	if [ -f ./create-html.prv.sh ]; then
		./create-html.prv.sh
	fi
}


reset_markdown_files() {
	for tlang in ${tlangs[@]}; do
		git checkout "../${tlang}/"
	done
}


tx_push_sources() {
	for sfile in ${sfiles[@]}; do
		txt2po --progress=none "../en/${sfile}.md" "translations/delta-chat-pages.${sfile}po/en.po"
	done
	tx push -s
}


if [ $1 == "tx-pull" ]; then
	tx_pull
elif [ $1 == "md-create" ]; then
	create_markdown_files	
elif [ $1 == "md-reset" ]; then
	reset_markdown_files
elif [ $1 == "push-sources" ]; then
	tx_push_sources
elif [ $1 == "pull" ]; then  # update translations from transifex using english as template, update markdown
	tx_pull
	create_markdown_files
	create_html_files
else
	echo "usage: ./t-dance {pull|tx-pull|md-create|md-reset|push-sources}";
	echo "to push a single language: tx push -t -l <lang>"
fi

