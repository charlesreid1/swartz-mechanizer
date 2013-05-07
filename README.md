# swartz-mechanizer #

A repository of scripts for scraping academic papers from the web.

In Memoriam [Aaron Swartz](http://en.wikipedia.org/wiki/Aaron_Swartz).

![Screenshot of swartz-mechanizer in action](/notes/swartz-mechanizer_in_action.png "screenshot of swartz-mechanizer in action")

## Before You Begin ##

### Please Make A Note ###

This is all work in progress. It is also all terribly-written Perl. I know my Perl is atrociously hacked, but hey, it works.

Currently, functionality is only for ScienceDirect journals.

### Prerequisites ###

#### Prerequisite: Perl CPANM ####

To install Perl Mechanize, first install cpanm (a.k.a. cpanimus), which is a Perl module that takes care of downloading, building, and installing Perl modules 
without bothering the user with prerequisites or prompts or other annoying things. Install cpanm by doing a bootstrap install:

```bash
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
```

Once you do this, you should be able to type "which cpanm" and see a result.

This method may give you errors, if your Perl system is old and components are in need of updating. In that case, you can use an alternative installation method. First, run the CPAN module, and update your CPAN:

```bash
perl -MCPAN -e 'install Bundle::CPAN'
```

(This may take a while.) Then, install cpanm:

```bash
perl -MCPAN -e 'install App::cpanimus'
```

Note that if you have multiple Perl versions, you can sometimes get cpanm associated with the wrong Perl, and then things get all messed up. When you type "which perl" and "which cpanm", they should be in the same place.

#### Prerequisite: Perl Mechanize ####

Now you should be able to install mechanize by running 

```bash
cpanm WWW::Mechanize 
```

#### Prerequisite: Mozilla Cookie Jar ####

You will also need a Mozilla cookie jar to run at least one of these scripts. To install, do the following:

```bash
cpanm HTTP::Cookies::Mozilla
```

## The Swartz Mechanizer Scripts ##

### Science Direct (sciencedirect.pl) ###

This script uses Mechanize to download papers from a ScienceDirect journal page. A list of all ScienceDirect journals may be found [on the ScienceDirect.com website](http://www.sciencedirect.com/science/journals).

You provide a URL for the journal you are interested in, and optionally a volume and issue number. The script will then iterate through each paper in whatever set you specified, and download the papers to disk.

Here is a breakdown of the process:
- You specify a journal url, and (optionally) a volume/issue number.
- The script initializes a Schwartz-Mechanizer object.
- The script determines if you want to download a whole journal, a whole volume, or a whole issue.
- If you specify a whole journal, it starts from the latest volume and iterates backwards through each volume number.
- If you specify a whole volume, it starts from the latest issue and iterates backwards through each issue number.
- For each issue, the script assembles an array of links to articles listed on the page.
- The script then loops through the array and downloads the articles to PDF files.
- The script repeats this for each issue of each volume.

The script isn't terribly intelligent, so don't assume it will handle mistakes gracefully. 

If a non-existent issue number is given, it will default to downloading the latest issue number.

If a non-existent volume number is given, it will default to downloading the latest volume number.

If a weird case (like a multi-issue bundle, or an in-progress issue) is encountered, the script will do its best. 

In the case that something goes wrong, you will probably have to edit the get_journal_info() function. (The get_journal_info() function needs to be able to understand and parse the TITLE tags on the page to function properly. This could/should be changed to look more intelligently in other places.)

If you need more fine-tuned control over the range of volumes or issues to download, I suggest combining this script with bash for loops. 

This is meant to be a barely-sufficient script, and thus will not have a bunch of bells and whistles.

Usage:

```bash
perl sciencedirect.pl [url] [volume] [issue]
```

Example: download the Proceedings of the Combustion Institute, Volumes 34-28 (which is as far back as the volumes go for Proceedings of the Combustion Institute):

```bash
perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/15407489' 
```

Example: download Applied Thermal Engineering, Volume 52:

```bash
perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/13594311' 52
```

Example: download the Journal of Systems and Software, Volume 81, Issue 4:

```bash
perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/01641212' 81 4
```

