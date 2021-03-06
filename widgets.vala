/* Copyright 2016 Camilo Higuita(milohr)
*
* This file is part of Babe Music Player.
*
* Babe is free software: you can redistribute it
* and/or modify it under the terms of version 3 of the
* GNU General Public License as published by the Free Software Foundation.
*
* Babe is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Babe. If not, see http://www.gnu.org/licenses/.
*/
using Gtk;
using Gst;
using Xml;
using Soup;
using BabeStream;
using CoverArt;
using BabeLyric;
using BabeList;
using BabePlayList;

namespace BabeWidgets {
const string playlist_path="./Playlist/";

public class BabeWindow : Gtk.Window //creates main window with all widgets alltogether...not ideal but...
{
	public StreamBabe babe_stream;
	public LastFm artwork;
	public BList main_list;
	public BList queue_list;
	public BList babes_list;
	public BList playlist;
	public BPlayList playlist_list;
	public LyricsManiaFetcher babe_lyric;
	public int queue_c=0;
	public int c=0;	//number of songs on the babed list
	public int mini=0; //state of the mini/maxi view
	public int shuffle=0; //whether the playback is on shuffle(0) or not(1)
	public string check=""; //placeholder to check if we already have an album cover art
	public string album_art; //placeholder to check if we already have an album cover art
	public Gdk.Pixbuf cover_pixbuf; //the pixbuf of the coverart of the current song to use when wanted or needed
	public Gtk.TreeIter iter_aux;

	//control view mode. pretty useless right now
	public int list_int=0;
	public int info_int=0;
	public int playlist_int=0;
	public int babe_int=0;
	public int queue_int=0;

	public string song; //this is the main uri to send to the streamer and start playback
	public string title=""; //title of current song
	public string artist=""; //artist of the current song
	public string album=""; //album of the current song

	//headerbar
	public Gtk.Image cover;//here the album artwork
	public Gtk.EventBox art_header;
	public Gtk.Popover playbox_popover;//still unused
	public Gtk.EventBox playback_box_event;
	public Gtk.Revealer playback_box_revealer; //reveals the playback actions box
	public Gtk.Box playback_box;
	public Gtk.Image options;

	//main containers
	public Gtk.Box main_container;
	public Gtk.Box media_box;
	public Gtk.Separator h_separator;
	public Gtk.Revealer media_revealer;

	//view modes
	public Gtk.Stack media_stack;
	public Gtk.Stack babe_info_stack;//to-do
	public Gtk.Label info_box_label;
	public Gtk.Box info_box;
	public Gtk.Menu menu;
	
	//playback box
	public Gtk.Box playback_buttons;
	public Gtk.Scale progressbar;

	public Gtk.Image play_icon;
	public Gtk.Image next_icon;
	public Gtk.Image previous_icon;
	public Gtk.Image babe_icon;

	public Gtk.EventBox play_icon_event;
	public Gtk.EventBox next_icon_event;
	public Gtk.EventBox previous_icon_event;
	public Gtk.EventBox babe_icon_event;

	public Gtk.Label stream_dur;
	public Gtk.Label stream_pos;


	//PLAY LISTS IN MEDIA_BOX
	private Gtk.TreeIter iter;
	private Gtk.TreeModel model;
	private Gtk.TreeModel previous_model;

	//info view
	private Gtk.Box info_view ;
	private ScrolledWindow info_list_scroll;
	//status bar
	public Gtk.ActionBar statusbar;

	public Gtk.Label status_label;

	public Gtk.Popover add_playlist_popover;

	public Gtk.Entry add_playlist_entry;

	public Gtk.EventBox add_playlist_event;
	public Gtk.EventBox shuffle_event;
	public Gtk.EventBox open_event;
	public Gtk.EventBox hide_event;

	public Gtk.Image add_playlist_icon;
	public Gtk.Image shuffle_icon;
	public Gtk.Image open_icon;
	public Gtk.Image hide_icon;

	//sidebar

	public Gtk.Popover settings_popover;
	public Gtk.Box settings_box;
	private Gtk.ListBox babe_sidebar;

	private Gtk.ListBoxRow babe_list;
	private Gtk.ListBoxRow babe_info;
	private Gtk.ListBoxRow babe_babes;
	private Gtk.ListBoxRow babe_playlist;
	private Gtk.ListBoxRow babe_queue;

	public BabeWindow()
	{
		this.get_style_context().add_class("babe-window");
		this.title = "Babe...";
		iter_aux = Gtk.TreeIter();
		this.window_position = WindowPosition.CENTER;
		this.set_resizable(false);
		//this.set_decorated(false);

		//this.set_default_size (200, 0);
		this.destroy.connect(Gtk.main_quit);

		cover=new Gtk.Image();
		this.cover.set_from_file ("img/babe.png");

        babe_stream=new StreamBabe(); //this is the main pipeline for streaming
        artwork = new LastFm(); //this is to get the album art
        babe_lyric= new LyricsManiaFetcher();
        
        main_list = new BList(false,"");
        babes_list=new BList(true,".Babes.txt");
        queue_list=new BList(false,"");
        playlist_list=new BPlayList();
		set_playlists();
        //Sets everything we need up
		set_babe_sidebar();
		set_babe_statusbar();
		set_babe_playback_box();
		set_babe_style();
		

		/***
		**SETUP HEADER WIDGETS
		***/

		//open music event
		open_icon = new Gtk.Image.from_icon_name("folder-open-symbolic", Gtk.IconSize.MENU);
		open_icon.get_style_context().add_class("options_icon");
		open_event = new Gtk.EventBox();
		open_event.add(open_icon);
		open_icon.set_tooltip_text ("Open...");
		open_event.button_press_event.connect (() => {
					main_list.on_open();
					return true;
		});

		//option event- to-finish
		options= new Gtk.Image.from_icon_name("go-jump-symbolic", Gtk.IconSize.MENU);
		options.get_style_context().add_class("options_icon");
		var options_event=new Gtk.EventBox();
		options_event.set_tooltip_text("Options");
		options_event.add(options);

		bool op=false;
		options_event.button_press_event.connect (() => {
			if(op==false)
			{
				cover.set_from_file("img/babe_back.png");
				op=true;

			}else
			{
				cover.set_from_pixbuf(cover_pixbuf);
				op=false;
			}
			return true;
		});
		//playback box
		playback_box = new Gtk.Box(Gtk.Orientation.VERTICAL,10);
		h_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
		playback_box.add(playback_buttons);
		playback_box.add(progressbar);
		//playback_box.add(h_separator);
		playback_box.set_spacing(-1);

		//pack playback_box inside an eventbox
		playback_box_event=new Gtk.EventBox();
		playback_box_event.add(playback_box);
		playback_box_event.get_style_context().add_class("playback_box");

		//let's pack now the playback_box_event into a revelaer
		playback_box_revealer=new Gtk.Revealer();
		playback_box_revealer.set_transition_type(RevealerTransitionType.CROSSFADE);
		//playback_box_revealer.set_transition_duration(300);
		playback_box_revealer.add(playback_box_event);
	
		//let's fix their positions to overlap them
		Gtk.Fixed fixed = new Gtk.Fixed ();
		fixed.put(cover,0,0);
		fixed.put(options_event,180,5);
		fixed.put(open_event,5,5);
		fixed.put(playback_box_revealer,45, 150);

		//let's make sure here that the revealer works allright
		playback_box_event.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
		playback_box_event.enter_notify_event.connect (reveal_playback_box);
        //art_header.leave_notify_event.connect (hide);
        //art_header.set_vexpand(true);

        //now we put the fixed box inside a new eventbox to make it the header/titlebar
        art_header = new Gtk.EventBox();//
        art_header.add(fixed);
        art_header.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
		art_header.enter_notify_event.connect (reveal_playback_box);
        art_header.leave_notify_event.connect (hide_playback_box);
        //art_header.set_visible_child_name("head_cover");
        this.set_titlebar(art_header); //this sets the album art as headerbar

		/***
		**SETUP ALL OTHER WIDGETS
		***/

		//main view: sidebar->lists view
		media_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
		Gtk.Separator v_separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		media_box.add(babe_sidebar);
		media_box.add(v_separator);
		media_box.pack_end(media_stack,true,true,0);

		//main container: main view->statusbar
		main_container = new Gtk.Box(Gtk.Orientation.VERTICAL,0);
		main_container.add(h_separator);
		media_revealer=new Gtk.Revealer();
		media_revealer.set_transition_type(RevealerTransitionType.SLIDE_UP);
		media_revealer.add(media_box);
		main_container.add(media_revealer);
		main_container.pack_end(statusbar,false,false,0);

		//the constant calls to needed functions
		GLib.Timeout.add_seconds(30, (SourceFunc) this.hide_playback_box);
		GLib.Timeout.add_seconds(8, (SourceFunc) this.update_status);
		GLib.Timeout.add (1000, (SourceFunc) this.update_media_controls);

		//add the main container to the babe window
		media_revealer.set_reveal_child(true);
		this.add(main_container);
	}

	public bool reveal_playback_box()
	{
		playback_box_revealer.set_reveal_child(true);
		return true;
	}

	public bool hide_playback_box()
	{
		playback_box_revealer.set_reveal_child(false);
		return true;
	}

	public void set_babe_playback_box()
	{
		//playbox_popover = new Gtk.Popover();
		progressbar = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 50, 1);
		progressbar.hexpand = true;
		progressbar.set_draw_value (false);
		progressbar.set_sensitive(false);
		progressbar.button_release_event.connect(on_media_seeked);

		stream_pos = new Gtk.Label ("0:00");
        stream_dur = new Gtk.Label ("0:00");
        stream_pos.margin= 6;
        stream_dur.margin = 6;
        progressbar.margin_start=5;
		progressbar.margin_end=5;

		//setup playback icons
		playback_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL,10);
		play_icon = new Gtk.Image.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.MENU);
		next_icon = new Gtk.Image.from_icon_name("media-skip-forward-symbolic", Gtk.IconSize.MENU);
		previous_icon = new Gtk.Image.from_icon_name("media-skip-backward-symbolic", Gtk.IconSize.MENU);
		babe_icon= new Gtk.Image.from_icon_name("emblem-favorite-symbolic", Gtk.IconSize.MENU);
		playback_buttons.margin_start=6;
		playback_buttons.margin_end=6;
		playback_buttons.margin_top=5;

		//setup playback buttons event
		play_icon_event=new Gtk.EventBox ();
		next_icon_event=new Gtk.EventBox ();
		previous_icon_event=new Gtk.EventBox ();
		babe_icon_event =new Gtk.EventBox ();

		play_icon_event.add(play_icon);
		next_icon_event.add(next_icon);
		previous_icon_event.add(previous_icon);
		babe_icon_event.add(babe_icon);

		//pack them in playback horizontal box
		//playback_buttons.pack_start(stream_pos, false, false, 0);
		playback_buttons.pack_start(previous_icon_event,true,true,1);
		playback_buttons.pack_start(babe_icon_event,true,true,1);
		playback_buttons.pack_start(play_icon_event,true,true,1);
		playback_buttons.pack_start(next_icon_event,true,true,1);
		//playback_buttons.pack_end(stream_dur, false, false, 0);

		//progressbar.set_tooltip_text(stream_pos.get_text()+" of "+stream_dur.get_text());
	}

	public void set_babe_sidebar()
	{
		babe_sidebar = new Gtk.ListBox();

		babe_list = new Gtk.ListBoxRow();
		var icon = new Gtk.Image.from_icon_name("emblem-music-symbolic", Gtk.IconSize.MENU);
		babe_list.add(icon);
		babe_list.set_tooltip_text ("List");

		babe_info = new Gtk.ListBoxRow();
		icon = new Gtk.Image.from_icon_name("media-optical-cd-audio-symbolic", Gtk.IconSize.MENU);
		babe_info.add(icon);
		babe_info.set_tooltip_text ("Info");

		babe_playlist= new Gtk.ListBoxRow();
		icon = new Gtk.Image.from_icon_name("media-tape-symbolic", Gtk.IconSize.MENU);
		babe_playlist.add(icon);
		babe_playlist.set_tooltip_text ("Playlists");

		babe_babes = new Gtk.ListBoxRow();
		icon = new Gtk.Image.from_icon_name("emblem-favorite-symbolic", Gtk.IconSize.MENU);
		babe_babes.add(icon);
		babe_babes.set_tooltip_text ("Babes <3");

		babe_queue = new Gtk.ListBoxRow();
		icon = new Gtk.Image.from_icon_name("document-open-recent-symbolic", Gtk.IconSize.MENU);
		babe_queue.add(icon);
		babe_queue.set_tooltip_text ("Queued");

		babe_sidebar.insert(babe_list, 0);
		babe_sidebar.insert(babe_info, 1);
		babe_sidebar.insert(babe_playlist, 2);
		babe_sidebar.insert(babe_babes, 3);
		babe_sidebar.insert(babe_queue, 4);
		info_box_label=new Gtk.Label("No song");


		info_view=new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		info_view.add(info_box_label);
		icon = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.MENU);
		Gtk.EventBox settings_event = new Gtk.EventBox();
		settings_event.add(icon);
		babe_sidebar.insert(settings_event,5);

		var op1=new Gtk.MenuItem.with_label("Clean Babes");
		var op2=new Gtk.MenuItem.with_label("Clean List");


		op1.activate.connect(clean_babe_list); //empty the babe'd list
		op2.activate.connect(() => {
			//babe_stream.set_state(Gst.State.NULL);
			main_list.get_liststore().clear();
			//media_stack.set_visible_child_name("add");

		});//empty the babe'd list
		var caja = new Gtk.Box(Gtk.Orientation.VERTICAL,0);
				caja.add(op1);
				caja.add(op2);
		settings_popover=new Gtk.Popover(settings_event);
		settings_popover.add(caja);
		settings_event.button_press_event.connect (() => {
			settings_popover.show_all();
			return true;
		});

		set_babe_lists();
	}

	public void clean_babe_list()
	{
		//babe_stream.set_state(Gst.State.NULL);
		FileStream.open (".Babes.txt","w");
		babes_list.get_liststore().clear();
		c=0;
		babe_babes.set_tooltip_text (c.to_string()+" Babes <3");
	}

	public void set_babe_lists()
	{
		
		info_box_label=new Gtk.Label("No song");

		info_view=new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		info_view.add(info_box_label);

		info_list_scroll.set_min_content_height(200);
		info_list_scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		info_list_scroll.add (info_view);


        set_babe_stacks();

	}

	public void set_babe_stacks()
	{
		media_stack= new Gtk.Stack();

        media_stack.set_vexpand(true);//main list
        media_stack.set_vexpand(true);//babes list
        media_stack.set_vexpand(true);//playlists list
        media_stack.set_vexpand(true);//queued list
        media_stack.set_vexpand(true);//info list

		//image holder to add music
		/*add_music_img = new Gtk.Image();
		add_music_img.set_from_file("img/add.png");
		add_music_event = new Gtk.EventBox();
		add_music_event.add(add_music_img);
		add_music_event.button_press_event.connect (() => {
					on_open();
					return true;
		});*/

		//set up babe view modes
		media_stack.add_named(main_list, "list");
		media_stack.add_named(playlist_list, "playlist");
		media_stack.add_named(babes_list, "babes");
		media_stack.add_named(queue_list, "queue");
		media_stack.add_named(info_list_scroll, "info");

		//start by default empty list
		//media_stack.set_visible_child_name("add");
		//get the babe list
		
		list_selected(main_list.get_treeview(), main_list.get_liststore());
		list_selected(queue_list.get_treeview(), queue_list.get_liststore());
		list_selected(babes_list.get_treeview(), babes_list.get_liststore());

		//catch sidebar selection
		babe_sidebar.row_activated.connect ((row => {
			if(row==babe_list)
			{
				//babe_icon_event.set_sensitive(true);
				print ("babe_list\n");
				media_stack.set_visible_child_name("list");
				list_int=1;
			}
			if(row==babe_info)
			{
				//set_babe_cover(get_babe_head());
				print ("babe_info\n");
				//media_stack.set_visible_child_name("list");
				status_label.label="Info not avalible";
				media_stack.set_visible_child_name("info");
				info_int=1;
			}
			if(row==babe_playlist)
			{
				print ("babe_playlist\n");
				media_stack.set_visible_child_name("playlist");
				playlist_list.show_main_list();
				
							status_label.label="000 Playlists";
				playlist_int=1;
			}
			if(row==babe_babes)
			{
				//get_babe_list();//awful solution
				print ("babe_babes\n");
				media_stack.set_visible_child_name("babes");
				babe_int=1;
			}
			if(row==babe_queue)
			{
				print ("babe_queue\n");
				media_stack.set_visible_child_name("queue");
				queue_int=1;
			}
		}));
	}

	public void set_babe_statusbar()
	{
		statusbar = new Gtk.ActionBar();

		//events on the statusbar
		shuffle_event = new Gtk.EventBox();
		add_playlist_event = new Gtk.EventBox();
		hide_event = new Gtk.EventBox();

		//components
		add_playlist_popover = new Gtk.Popover(add_playlist_event);
		add_playlist_entry = new Gtk.Entry();

		//main info label
		status_label = new Gtk.Label("");
		status_label.set_line_wrap(true);
		status_label.set_max_width_chars (14);
		status_label.set_ellipsize (Pango.EllipsizeMode.END);
		//status_label.move_cursor(MovementStep.VISUAL_POSITIONS, 100, false);
		status_label.set_lines(1);

		//set playlist entry
		add_playlist_entry.set_placeholder_text("Create new...");
		add_playlist_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY,"media-tape-symbolic");//nombre
        add_playlist_entry.icon_press.connect((pos, event)=>{
                if(pos == Gtk.EntryIconPosition.SECONDARY){
                    this.add_playlist_entry.set_text("");
                    }
                });

		add_playlist_entry.activate.connect (() => {
			string str = add_playlist_entry.get_text();
			playlist_list.add_playlist(str);
			add_playlist_entry.set_text("");
			status_label.label="Playlist Created";
		});

        add_playlist_popover.add(add_playlist_entry);

		//shuffle event //TO-DO
		shuffle_icon= new Gtk.Image.from_icon_name("media-playlist-no-shuffle-symbolic", Gtk.IconSize.MENU);
		shuffle_event.add(shuffle_icon);

		shuffle_icon.set_tooltip_text ("Shuffle");
		bool state=true;

		shuffle_event.button_press_event.connect (() => {
					if (state==true)
					{
					shuffle_icon.set_from_icon_name("media-playlist-shuffle-symbolic", Gtk.IconSize.MENU);
					shuffle_icon.set_tooltip_text ("Normal");
					shuffle=0;
					state=false;
					}else
					{
					shuffle_icon.set_from_icon_name("media-playlist-no-shuffle-symbolic", Gtk.IconSize.MENU);
					shuffle_icon.set_tooltip_text ("Shuffle");
					shuffle=1;
					state=true;
					}
				return true;
		});

		//add new playlist event //TO-DO
		add_playlist_icon = new Gtk.Image.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
		add_playlist_event.add(add_playlist_icon);

		add_playlist_icon.set_tooltip_text ("Create Playlist");
		add_playlist_event.button_press_event.connect (() => {
					c++;
					add_playlist_popover.show_all();
					return true;

		});

		//hide event
		hide_icon= new Gtk.Image.from_icon_name("go-up-symbolic", Gtk.IconSize.MENU);
		hide_event.add(hide_icon);
		hide_icon.set_tooltip_text ("Go Mini");
		mini=0;

		hide_event.button_press_event.connect (() => {
					switch(mini)
					{
						case 0:
							if(babe_stream.is_playing())
							{
								this.set_keep_above(true);
							}else
							{
								this.set_keep_above(false);
							}
							playback_box_revealer.set_reveal_child(false);
							media_revealer.set_reveal_child(false);
							h_separator.hide();
							hide_icon.set_tooltip_text ("Go Maxi");
							hide_icon.set_from_icon_name("go-down-symbolic", Gtk.IconSize.MENU);
							mini=1;
						break;

						case 1:
							this.set_keep_above(false);
							h_separator.show();
							media_revealer.set_reveal_child(true);
							hide_icon.set_from_icon_name("go-up-symbolic", Gtk.IconSize.MENU);
							hide_icon.set_tooltip_text ("Go Mini");
							mini=0;
						break;
					}
				return true;
		});

		statusbar.pack_start(add_playlist_event);
		statusbar.pack_start(shuffle_event);
		statusbar.set_center_widget(status_label);
		//statusbar.pack_end(open_event);
		statusbar.pack_end(hide_event);
		//statusbar.pack_start(shuffle_event);
	}


	

	public TagLib.File get_song_info(string uri)//it actually turn a uri into a path to be able to get the tags
	{
		var gfile = GLib.File.new_for_uri (uri);
		string nm=gfile.get_path() ;
		var info =  new TagLib.File(nm);
		return info;
	}

	public  async void set_babe_cover(string cover_file)
	{
		if(cover_file=="img/babe.png"){
			cover.set_from_file(cover_file);
		}else
		{
			cover_pixbuf=artwork.download_cover_art(cover_file);

			if (cover_pixbuf==null)
			{
				cover.set_from_file("img/babe.png");
			}else
			{
				var scaled_buf = cover_pixbuf.scale_simple(200,200, Gdk.InterpType.BILINEAR);
				cover_pixbuf=scaled_buf;
				cover.set_from_pixbuf(scaled_buf);
			}
		}
			//g.set_color(cover_file, playback_box);//to assign the most prominent color of coverart to certain widget
	}

	public  string get_babe_cover()
	{
		string default_cover="img/babe.png";

		if(check==album+artist)
		{
			print("We already got that album cover\n");
			return album_art;
		}else
		{
			print("Getting album art for: "+album+" by "+artist+"\n");
			if(album==""||artist=="")
			{
				print("Not enought info to get the album cover. So let's try sth here'\n");
				album_art=artwork.get_art_uri(title, artist);
				if(album_art==null)
				{
					return default_cover;
				}else
				{
					return album_art;
				}
			}else
			{
				check=album+artist;
				album_art=artwork.get_art_uri(album, artist);
				if(album_art==null)
				{
					return default_cover;
				}else
				{
					return album_art;
				}
			}
		}
	}

	public string get_babe_head()//to do
	{
		string artist_head;

		if(artist=="")
		{
			return "babe.png";
		}else
		{
			artist_head=artwork.get_artist_uri(artist);
			if(artist_head==null)
			{
			return "babe.png";
			}else
			{
				return artist_head;
			}
		}
	}

	public void list_selected(Gtk.TreeView view, Gtk.ListStore list)//actions done to the current list selected
	{
		//right click event
		
		view.add_events (Gdk.EventType.BUTTON_PRESS);
		view.button_press_event.connect (on_right_click);
		//double click event
		view.row_activated.connect(this.on_row_activated);
		//var selection = view.get_selection ();
		//selection.changed.connect (get_selection);
	}


	public bool on_right_click (Gtk.Widget widget, Gdk.EventButton event) //catches the right lcick event
	{		
		var treeview = (Gtk.TreeView) widget;
	
		Gtk.TreePath path=new Gtk.TreePath();
		string song_uri, title_r, artist_r,album_r; //to avoid problems with global string of title, artist and album and song
		if (event.type == Gdk.EventType.BUTTON_PRESS  &&  event.button == 3)
		{

			//var selection = main_list_view.get_selection();
			if(treeview.get_path_at_pos((int)event.x,(int)event.y,out path,null, null, null))
			{
				var model=treeview.get_model();
				if (treeview.model.get_iter (out iter, path)) {
						model.get (iter,
                        4, out title_r,
						1, out artist_r,
						2, out song_uri,
						3, out album_r);

						set_list_action(song_uri, iter, model, treeview);
						menu.popup(null,null,null,event.button, event.time);
				print ("Single right click on the tree view: "+title_r+" +++ "+artist_r+" \n");

				}


			}
			return true;
		}else
		{
			return false;
		}

	}

	public void set_list_action(string line, Gtk.TreeIter iter, Gtk.TreeModel model, Gtk.TreeView treeview )
	{
	menu = new Gtk.Menu();

	var item1= new Gtk.MenuItem.with_label("Babe it \xe2\x99\xa1");
	var item2= new Gtk.MenuItem.with_label("Remove it");
	var item3= new Gtk.MenuItem.with_label("Queue it");
	var item4= new Gtk.MenuItem.with_label("Add to playlist");

	var submenu= new Gtk.Menu();
	add_to_playlist_submenu(submenu, line);
	submenu.show_all();
	item4.set_submenu(submenu);
	
	item1.activate.connect(()=>{
		print("accion#1");
		song=line;
		add_babe(iter);
	});
	
	
	
	item2.activate.connect(()=>{
		var list_store=(Gtk.ListStore) treeview.get_model();

			list_store.remove(iter);
		get_BList_object(model).modify_c();


		print("accion#2");
	});

	item3.activate.connect(()=>{
		print("accion#3");
		song=line;
		add_queue(iter);
	});
	item4.activate.connect(()=>{
		print("accion#4");
	});
	
	
	menu.append(item1);
	menu.append(item2);
	menu.append(item3);
	menu.append(item4);
	menu.show_all();
	}
	
	private void add_to_playlist_submenu(Gtk.Menu submenu, string line)
	{
		var directory = GLib.File.new_for_path (playlist_path);
		try 
		{					
			var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) 
			{        
				GLib.File path = enumerator.get_child (file_info);
				if( file_info.get_name ().has_suffix(".babe"))
				{	
					var item= new Gtk.MenuItem.with_label(file_info.get_name ().replace(".babe",""));
					submenu.append(item);
					item.activate.connect(()=>{
					print(item.get_label());
					add_to_playlist(line, item.get_label()+".babe");
	});
				}
				
				
					
			}

		} catch (GLib.Error e)
		{
			stderr.printf ("Error: %s\n", e.message);
      
		} 			
        
		
	}
	public void set_playlists()
	{	string line;	
		var directory = GLib.File.new_for_path (playlist_path);
		 
		if (!(directory.query_exists()))
		{
           		try
           		{
					directory.make_directory();
				}catch(GLib.Error e)
				{
					print("clound't create Playlist dir");
				}	
        }
        try 
		{					
			var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) 
			{      
				
				GLib.File path = enumerator.get_child (file_info);
				if( file_info.get_name ().has_suffix(".babe"))
				{
					line=file_info.get_name ();  
					 playlist=new BList(true,"./Playlist/"+file_info.get_name ());
					playlist_list.populate(line, playlist);
					list_selected(playlist.get_treeview(),playlist.get_liststore());					 

				}
			}

		} catch (GLib.Error e)
		{
			stderr.printf ("Error: %s\n", e.message);
      
		} 			
	}
	
	public bool list_store(Gtk.Widget widget, Gdk.EventButton event)
	{
		if (event.type == Gdk.EventType.BUTTON_PRESS &&  event.button == 3)
		{
				print("oooooootyyyy");

	}else
	{
		var list=(BList) widget;
		list.proff();
		var aux=list.get_liststore();
	}
		return true;
	}
	
	public void add_to_playlist(string song_uri, string path )
	{
			string full_path=playlist_path+path;
			FileStream file = FileStream.open (full_path,"a");
			assert (file != null);
			file.puts (song_uri+"\n");
			
			status_label.label="Song added!";
			//playlist.populate(song_uri);
			notify("Song added to playlist!",get_song_info(song_uri).tag.title+" \xe2\x99\xa1 "+get_song_info(song_uri).tag.artist);
				
	}
	
	private void on_row_activated (Gtk.TreeView treeview, Gtk.TreePath path, Gtk.TreeViewColumn column) //double click starts playback
	{
		previous_model=model;
		model=treeview.get_model();

        if (treeview.model.get_iter (out iter, path)) {
		model.get (iter,
                        4, out title,
						1, out artist,
						2, out song,
						3, out album);

		start_playback_actions();
        }


		//skipping songs
        next_icon_event.button_press_event.connect (() => {
			get_next_song();
			notify(title,artist+" \xe2\x99\xa1 "+album);
			return true;
		});

		previous_icon_event.button_press_event.connect (() => {
			get_previous_song();
			notify(title,artist+" \xe2\x99\xa1 "+album);
			return true;
		});

		//check end of stream to start the next song
		babe_stream.playbin.bus.add_watch (0, (bus, msg) => {
			if (msg.type == Gst.MessageType.EOS)
			{
				get_next_song();

			}
				return true;
		});
    }

	public bool test(string testing)
	{
		print("the test on: "+testing);
		return true;
	}

	
	public Gtk.ListStore get_liststore(Gtk.TreeModel model)
	{

		if(model==main_list.get_liststore())
		{
			return main_list.get_liststore();
		}else if(model==babes_list.get_liststore())
		{
			return babes_list.get_liststore();
		}else if(model==queue_list.get_liststore())
		{
			return queue_list.get_liststore();
		}else if(model==playlist.get_liststore())
		{
			return playlist.get_liststore();
		}		else
		{return null;
		}

	}
	
	public BList get_BList_object(Gtk.TreeModel model)
	{

		if(model==main_list.get_liststore())
		{
			return main_list;
		}else if(model==babes_list.get_liststore())
		{
			return babes_list;
		}else if(model==queue_list.get_liststore())
		{
			return queue_list;
		}else
		{return null;
		}

	}

	public void start_playback_actions()
	{

		babe_stream.uri(song);
		get_lyrics();
		play_icon.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.MENU);
		update_status();
		update_cover();
		enable_playbox_events();
		playback_box_revealer.set_reveal_child(true);
		progressbar.set_sensitive(true);

		if(!(this.is_active ))
		{
			notify(title,artist+" \xe2\x99\xa1 "+album);
		}

		if(!(check_babe(song)))
		{
			babe_icon.set_state_flags(StateFlags.CHECKED, true);
		}
	}

public async void get_lyrics()
{
	string lyrics=babe_lyric.fetch_lyrics(title,album,artist);
		print(lyrics+"\n");
		info_box_label.label=lyrics;
}
	public void notify(string s, string b)
	{
		string icon = "dialog-information";
		try
		{
			Notify.Notification notification = new Notify.Notification (s, b, icon);
			notification.set_image_from_pixbuf(cover_pixbuf);
			notification.show ();
		} catch (GLib.Error e)
		{
			error ("Error: %s", e.message);
		}
	}

	public void enable_playbox_events()
	{
		//play-pause event
		bool playing=false;
		play_icon.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.MENU);

		play_icon_event.button_press_event.connect (() => {
			if(playing==false)
			{
				babe_stream.pause_song();
				play_icon.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.MENU);
				playing=true;
			}
			else
			{
				babe_stream.play_song();
				play_icon.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.MENU);
				playing=false;
			}

			return true;
		});

		//babe event
		babe_icon.set_state_flags(StateFlags.NORMAL, true);
		babe_icon_event.button_press_event.connect (() => {
			add_babe(iter);
			return true;
		});
	}

	public void play_queue()
	{
		print("There are: "+queue_c.to_string()+" songs in queue");
		model=queue_list.get_treeview().get_model();


		queue_c--;
	}

	public void get_next_song()
	{

		if(model==queue_list.get_liststore())
		{
			if(queue_list.get_liststore().remove(iter))
			{
				queue_c--;
			}
			else
			{
				model=previous_model;
				//iter=iter_aux;
			}
		}

		if(queue_c>0)
		{
			play_queue();

		}

		if(!(model.iter_next (ref iter)))
		{
			if(!(model.get_iter_first(out iter)))
			{
				babe_stream.set_state(State.NULL);
			}
		}


			model.get (iter,
                            4, out title,
							1, out artist,
							2, out song,
							3, out album);


		print("Playing next song->\n");
		print("Upcoming song: "+title+"\n");
		start_playback_actions();


	}

	public void get_previous_song()
	{
		if(model.iter_previous (ref iter))
			{
				model.get (iter,
                            4, out title,
							1, out artist,
							2, out song,
							3, out album);
			}
		print("<-Playing previous song\n");
		print("Previous song: "+title+"\n");
		start_playback_actions();

	}

	public void get_random_song(Gtk.TreeModel liststore)
	{
		bool random;
		int n;
		var iter_random = new Gtk.TreeIter();
		n=liststore.iter_n_children(iter);
		babe_icon.set_state_flags(StateFlags.NORMAL, true);

		random = liststore.iter_nth_child (out iter_random, iter, n);

		if(random==false)
		{
			random= liststore.get_iter_first(out iter);
		}

		model.get (iter_random,
                        4, out title,
						1, out artist,
						2, out song,
						3, out album);

		start_playback_actions();
		print("Playing random song<->\n");

	}

	public void add_babe(Gtk.TreeIter iter2)
	{
		string check_song=song;

		if(check_babe(check_song))//checks if the song already exists in the list
		{
			FileStream file = FileStream.open (".Babes.txt","a");
			assert (file != null);
			file.puts (song+"\n");

			babes_list.populate(song);

			status_label.label="Babe added!";

			notify("Babe added!",get_song_info(check_song).tag.title+" \xe2\x99\xa1 "+get_song_info(check_song).tag.artist);
			babe_icon.set_state_flags(StateFlags.CHECKED, true);

		}else
		{
			notify("Babe already added",":(");
			print("Already added\n");
		}
   	}

   	public void add_queue(Gtk.TreeIter iter2)
	{
		string queue_song=song;
	    queue_c++;
		queue_list.populate(queue_song);

		notify("Queue!",get_song_info(queue_song).tag.title+" \xe2\x99\xa1 "+get_song_info(queue_song).tag.artist);
   	}

    public bool check_babe(string c_song)
    {
		var file = GLib.File.new_for_path (".Babes.txt");
		bool checking=true;
		var dis = new DataInputStream (file.read());
        string line;
        // Read lines until end of file (null) is reached
        while ((line = dis.read_line (null)) != null)
        {
			if(line==c_song)
			{
				checking=false;
				print("we found that sonf existing in babes lst\n");

				line=null;
			}

        }
		return checking;
	}

	public  void update_status()
	{
		if (title=="" || artist=="" )
		{
			status_label.label=title+""+artist;
		}else
		{
			status_label.label=title+" \xe2\x99\xa1 "+artist;
			status_label.set_tooltip_text(title+" by "+artist);
		}
	}

	public async void update_cover()
	{
		set_babe_cover(get_babe_cover());
	}

	

	public void set_babe_style()
	{
		add_playlist_popover.get_style_context().add_class("babe-pop");
		babe_sidebar.get_style_context().add_class("babe");
		babe_icon.get_style_context().add_class("babed");
	}

	public void update_media_controls()
	{
		var dur = babe_stream.get_song_duration();
		var pos = babe_stream.get_song_position();

		int64 dur_seconds = (dur / 1000000000);
		int64 dur_minutes = (dur_seconds / 60);
		int64 dur_remainder = dur_seconds - (dur_minutes * 60);

		string dur_minute_string = dur_minutes.to_string ();
		string dur_seconds_string = dur_seconds.to_string ();
		string dur_remainder_string = dur_remainder.to_string ();

		progressbar.set_range (0, dur_seconds);

		int64 seconds = (pos / 1000000000);
		int64 minutes = (seconds / 60);
		int64 remainder = seconds - (minutes * 60);
		progressbar.set_value (seconds);
		string minute_string = minutes.to_string ();

		string remainder_string = remainder.to_string ();

		if (remainder < 10)
		{
			remainder_string = "0" + remainder_string;
		}

		if (dur_remainder< 10)
		{
		  dur_remainder_string = "0" + dur_remainder_string;
		}

        progressbar.set_tooltip_text(minute_string + ":" +remainder_string+
        " of "+dur_minute_string + ":" + dur_remainder_string);
     }

	 public bool on_media_seeked (Gdk.EventButton event)
	 {
        var pos = progressbar.get_value ();
        pos = pos * 1000000000;

        babe_stream.seek ((int64)pos);
        return false;
	}
} }
