DFF_generic_inst : DFF_generic PORT MAP (
		clock	 => clock_sig,
		enable	 => enable_sig,
		sclr	 => sclr_sig,
		sset	 => sset_sig,
		aclr	 => aclr_sig,
		aset	 => aset_sig,
		data	 => data_sig,
		q	 => q_sig
	);
