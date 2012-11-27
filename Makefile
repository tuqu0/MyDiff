DIR=MyDiff
DIST= puydoyeux_vincent-MyDiff

clean:
	rm -f ./src/*~
	rm -f ./*~
dist: clean
	rm -rf ../$(DIST) 2>/dev/null
	rm -rf ../$(DIST).zip 2>/dev/null
	mkdir ../$(DIST)
	cp -r ../$(DIR)/*  ../$(DIST)
	zip -9 -r ../$(DIST).zip ../$(DIST) 
	rm -rf ../$(DIST)
	sha512sum ../$(DIST).zip

