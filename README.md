swartz-mechanizer
===================
A repository of scripts for scraping academic papers from the web.

In Memoriam [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

Please Make A Note
-------------------
This is all work in progress. It is also all terribly-written Perl. Yup - I know my Perl is atrocious.

Currently, functionality is only for ScienceDirect journals. Next addition will be JSTOR.

Dependencies
---------------
You will need the Perl Mechanize module to run these scripts.

Prerequisite: Perl CPANM
--------------------------
To install Perl Mechanize, first install cpanm (a.k.a. cpanimus), which is a Perl module that takes care of downloading, building, and installing Perl modules 
without bothering the user with prerequisites or prompts or other annoying things. Install cpanm by doing a bootstrap install:

> curl -L http://cpanmin.us | perl - --sudo App::cpanminus

Once you do this, you should be able to type "which cpanm" and see a result.

Note that if you have multiple Perl versions, you can sometimes get cpanm associated with the wrong Perl, and then things get all messed up. When you type "which perl" and "which cpanm", they should be in the same place.

Prerequisite: Perl Mechanize
------------------------------
Now you should be able to install mechanize by running 

> cpanm WWW::Mechanize 

Prerequisite: Mozilla Cookie Jar
----------------------------------
You will also need a Mozilla cookie jar to run at least one of these scripts. To install, do the following:

> cpanm HTTP::Cookies::Mozilla

Script: sciencedirect.pl
-----------------
This script uses Mechanize to download papers from a ScienceDirect journal page.

It goes to the page of the journal (stock version uses the Proceedings of the Combustion Institute), grabs information about the journal title, volume, issue, and year, then iterates through the entire list of papers and downloads each.

In theory, it should also go to the next page, and download all of those papers.

In reality, currently, it can only download papers on the first page it goes to.

