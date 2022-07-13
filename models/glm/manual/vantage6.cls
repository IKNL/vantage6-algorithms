%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vantage6 Algorithm Documentation
% LaTeX Class
% Version 1.0 (05/01/2021)
%
% This class is based on the Diaz template from:
% http://www.LaTeXTemplates.com
%
% Authors:
% Frank (f.martin@iknl.nl)
% Vel (vel@LaTeXTemplates.com)
% Nicolas Diaz (nsdiaz@uc.cl)
%
% License:
% CC BY-NC-SA 3.0 (http://creativecommons.org/licenses/by-nc-sa/3.0/)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%----------------------------------------------------------------------------------------
%	CLASS CONFIGURATION
%----------------------------------------------------------------------------------------

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{vantage6}[2021/01/05 Vantage6 Algorithm Documentation class v1.0]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}} % Pass through any options to the base class
\ProcessOptions\relax % Process given options

\LoadClass{article} % Load the base class

%----------------------------------------------------------------------------------------
%	PACKAGES AND OTHER DOCUMENT CONFIGURATIONS
%----------------------------------------------------------------------------------------

\usepackage[english]{babel} % English language hyphenation

\usepackage{graphicx} % Required for including images
\graphicspath{{Figures/}{./}} % Specifies where to look for included images (trailing slash required)

\usepackage{wrapfig} % Allows in-line images

\usepackage{booktabs} % Required for better horizontal rules in tables

\usepackage{enumitem} % Required for list customisation
\setlist{noitemsep} % No spacing between list items

\makeatletter
\renewcommand\@biblabel[1]{\textbf{#1.}} % Remove the square brackets from each bibliography item ('[1]' to '1.')
\makeatother

\usepackage{algorithm} % used for algorithms
\usepackage{algpseudocode}

% tables
\usepackage[table]{xcolor}
\usepackage{multirow}
{\rowcolors{3}{white}{lightgray}

% codeblock
\usepackage{listings}
\definecolor{codegreen}{rgb}{0,0.6,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolour}{rgb}{0.95,0.95,0.92}

\lstdefinestyle{mystyle}{
    backgroundcolor=\color{backcolour},
    commentstyle=\color{codegreen},
    keywordstyle=\color{magenta},
    numberstyle=\tiny\color{codegray},
    stringstyle=\color{codepurple},
    basicstyle=\ttfamily,
    breakatwhitespace=false,
    breaklines=true,
    captionpos=b,
    keepspaces=true,
    numbers=left,
    numbersep=5pt,
    showspaces=false,
    showstringspaces=false,
    showtabs=false,
    tabsize=2
}

\lstset{style=mystyle}

\usepackage{hyperref}

%----------------------------------------------------------------------------------------
%	DOCUMENT MARGINS
%----------------------------------------------------------------------------------------

\usepackage{geometry} % Required for adjusting page dimensions and margins

\geometry{
	paper=a4paper, % Paper size, change to letterpaper for US letter size
	top=4cm, % Top margin
	bottom=2cm, % Bottom margin
	left=2cm, % Left margin
	right=2cm, % Right margin
	headheight=2.5cm, % Header height
	footskip=1.5cm, % Space from the bottom margin to the baseline of the footer
	headsep=0.75cm, % Space from the top margin to the baseline of the header
	%showframe, % Uncomment to show how the type block is set on the page
}

%----------------------------------------------------------------------------------------
%	FONTS
%----------------------------------------------------------------------------------------

\usepackage[utf8]{inputenc} % Required for inputting international characters
\usepackage[T1]{fontenc} % Use 8-bit encoding

%\usepackage{mathpazo} % Use the Palatino font

%\usepackage[protrusion=true, expansion=true]{microtype} % Better typography
\usepackage[default]{sourcesanspro}
\usepackage[T1]{fontenc}

\linespread{1.10} % Increase line spacing slightly; Palatino benefits from a slight increase by default

%----------------------------------------------------------------------------------------
%	TITLE
%----------------------------------------------------------------------------------------

\makeatletter
\renewcommand{\maketitle}{ % Customise the title (do not edit title and author name here)
	\vspace*{30pt} % Vertical whitespace before the title
	\begin{center} % Right align
		{\LARGE\@title} % Increase the font size of the title

		\vspace{50pt} % Vertical whitespace between the title and author name

		{\large\@author}\\ % Author name
		\@date % Date

		\vspace{40pt} % Vertical whitespace between the author block and abstract
	\end{center}
}
\makeatother

%----------------------------------------------------------------------------------------
%	HEADERS AND FOOTERS
%----------------------------------------------------------------------------------------
\graphicspath{ {./images/} }
\def\LOGO{%
\includegraphics[height=2cm]{small-logo.png}
}
\def\vantage6logo{%
\begin{center}
\includegraphics[width=.8\linewidth]{logo.png}
\end{center}
}

\usepackage{fancyhdr} % Required for customising headers and footers
\pagestyle{fancy} % Enable custom headers and footers

\renewcommand{\headrulewidth}{0pt} % Remove default top horizontal rule
\lhead{} % Left header
\chead{} % Centre header
\rhead{\LOGO} % Right header
\lfoot{} % Left footer
\cfoot{visit us at \textbf{ vantage6.ai }} % Centre footer
\rfoot{} % Right footer

% remove logo on first page
\fancypagestyle{firstpage}{%
  \chead{Algorithm documentation}
  \rhead{}
  \cfoot{}
}
