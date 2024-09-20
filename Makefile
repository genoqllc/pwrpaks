
PROJECT_NAME := wh3lk

BOARD := hardware/wh3lk.kicad_pcb
SCHEMATIC := hardware/wh3lk.kicad_sch
SCHEMATICS := hardware/*.kicad_sch
OUTPUTS_DIR := hardware/build
PREVIOUS_DIR := $(shell pwd)

LAYERS := F.Cu,In1.Cu,In2.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts

GIT_TAG := $(shell git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)

VERSIONED_BOARD := $(OUTPUTS_DIR)/$(PROJECT_NAME).$(GIT_TAG).kicad_pcb
VERSIONED_SCHEMATIC := $(OUTPUTS_DIR)/prep.$(GIT_TAG).kicad_sch

.PHONY: build
build: clean $(OUTPUTS_DIR) $(VERSIONED_BOARD) drc gerbers drill bom pos zip
	@echo "Building..."

$(OUTPUTS_DIR):
	@mkdir -p $(OUTPUTS_DIR)

$(VERSIONED_BOARD):
	@echo "Creating versioned board file..."
	@cp $(BOARD) $(VERSIONED_BOARD)
	@sed -i 's/__VER__/$(GIT_TAG)/' $(VERSIONED_BOARD)
	@cp $(SCHEMATICS) $(OUTPUTS_DIR)
	# @sed -i 's/__VER__/$(GIT_TAG)/' $(VERSIONED_SCHEMATIC)
	rename 's/\.kicad_sch/.$(GIT_TAG).kicad_sch/' $(OUTPUTS_DIR)/*.kicad_sch

.PHONY: ver
ver: $(OUTPUTS_DIR) $(VERSIONED_BOARD)

.PHONY: drc
drc: $(OUTPUTS_DIR) $(VERSIONED_BOARD)
	@echo "Running DRC..."
	kicad-cli pcb drc \
		--output $(OUTPUTS_DIR)/$(PROJECT_NAME).$(GIT_TAG).drc.rpt \
		--schematic-parity --severity-error --exit-code-violations \
		$(VERSIONED_BOARD)

.PHONY: gerbers
gerbers: $(OUTPUTS_DIR) $(VERSIONED_BOARD)
	@echo "Generating gerbers..."
	@mkdir -p hardware/build
	kicad-cli pcb export gerbers \
		--output $(OUTPUTS_DIR) \
		--layers "$(LAYERS)" \
		--subtract-soldermask \
		$(VERSIONED_BOARD)

.PHONY: drill
drill: $(OUTPUTS_DIR) $(VERSIONED_BOARD)
	@echo "Generating drill files..."
	kicad-cli pcb export drill \
		--output $(OUTPUTS_DIR) \
		--format excellon \
		--drill-origin absolute \
		--excellon-zeros-format decimal \
		--excellon-oval-format alternate \
		--excellon-units mm \
		--generate-map \
		--map-format gerberx2 \
		$(VERSIONED_BOARD)

.PHONY: bom
bom: $(OUTPUTS_DIR) $(VERSIONED_BOARD)
	@echo "Generating BOM..."
	@for schematic in $(OUTPUTS_DIR)/*.kicad_sch; do \
		kicad-cli sch export python-bom \
			--output $$schematic.bom.xml \
			$$schematic; \
		xsltproc -o \
			$$schematic.bom.csv \
			utils/bom2grouped_csv_jlcpcb.xsl \
			$$schematic.bom.xml; \
	done

	awk '(NR == 1) || (FNR > 1)' $(OUTPUTS_DIR)/*.csv > $(OUTPUTS_DIR)/$(PROJECT_NAME).$(GIT_TAG).bom.csv


.PHONY: pos
pos: $(OUTPUTS_DIR) $(VERSIONED_BOARD)
	@echo "Generating pick and place files..."
	kicad-cli pcb export pos \
		--output $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).pos.csv \
		--format csv \
		--units mm \
		--side both \
		$(VERSIONED_BOARD)

	# prep the pos file for JLCPCB
	@sed -i 's/Ref,Val,Package,PosX,PosY,Rot,Side/Designator,Val,Package,Mid X,Mid Y,Rotation,Layer/' $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).pos.csv

.PHONY: zip
zip: $(OUTPUTS_DIR)
	@echo "Zipping build outputs..."
	rm -rf $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).zip
	zip -j $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).zip $(OUTPUTS_DIR)/*

.PHONY: tag
tag:
	@echo $(GIT_TAG)

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf hardware/build/*
