
PROJECT_NAME := wh3lk

BOARD := hardware/wh3lk.kicad_pcb
SCHEMATIC := hardware/wh3lk.kicad_sch
OUTPUTS_DIR := hardware/build
PREVIOUS_DIR := $(shell pwd)

LAYERS := F.Cu,In1.Cu,In2.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts

GIT_TAG := $(shell git rev-parse --short HEAD)

.PHONY: build
build: clean $(OUTPUTS_DIR) drc gerbers drill bom pos zip
	@echo "Building..."

$(OUTPUTS_DIR):
	@mkdir -p $(OUTPUTS_DIR)

.PHONY: drc
drc: $(OUTPUTS_DIR)
	@echo "Running DRC..."
	kicad-cli pcb drc \
		--output $(OUTPUTS_DIR)/$(PROJECT_NAME).drc.rpt \
		--schematic-parity --severity-error --exit-code-violations \
		$(BOARD)

.PHONY: gerbers
gerbers: $(OUTPUTS_DIR)
	@echo "Generating gerbers..."
	@mkdir -p hardware/build
	kicad-cli pcb export gerbers \
		--output $(OUTPUTS_DIR) \
		--layers "$(LAYERS)" \
		--subtract-soldermask \
		$(BOARD)

.PHONY: drill
drill: $(OUTPUTS_DIR)
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
		$(BOARD)

.PHONY: bom
bom: $(OUTPUTS_DIR)
	@echo "Generating BOM..."
	kicad-cli sch export python-bom \
		--output $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).bom.xml \
		$(SCHEMATIC)

	xsltproc -o \
		$(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).bom.csv \
		utils/bom2grouped_csv_jlcpcb.xsl \
		$(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).bom.xml

.PHONY: pos
pos: $(OUTPUTS_DIR)
	@echo "Generating pick and place files..."
	kicad-cli pcb export pos \
		--output $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).pos.csv \
		--format csv \
		--units mm \
		--side both \
		$(BOARD)

	# prep the pos file for JLCPCB
	@sed -i 's/Ref,Val,Package,PosX,PosY,Rot,Side/Designator,Val,Package,Mid X,Mid Y,Rotation,Layer/' $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).pos.csv

.PHONY: zip
zip: $(OUTPUTS_DIR)
	@echo "Zipping build outputs..."
	rm -rf $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).zip
	zip -j $(OUTPUTS_DIR)/$(PROJECT_NAME)-$(GIT_TAG).zip $(OUTPUTS_DIR)/*

.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf hardware/build/*
